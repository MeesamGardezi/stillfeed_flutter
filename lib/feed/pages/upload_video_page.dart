import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../../config/routes.dart';
import '../../config/api_config.dart';
import '../../core/constants/dimensions.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadVideoPage extends StatefulWidget {
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dio = Dio();
  final _auth = FirebaseAuth.instance;

  File? _videoFile;
  VideoPlayerController? _videoController;
  VideoCategory _selectedCategory = VideoCategory.nature;
  
  bool _isProcessing = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  int _videoDuration = 0; // in seconds

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final file = File(pickedFile.path);

      // Validate file size (max 500MB)
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      
      if (fileSizeMB > 500) {
        setState(() {
          _errorMessage = 'Video file size exceeds 500MB limit';
          _isProcessing = false;
        });
        return;
      }

      // Validate file format
      final extension = pickedFile.path.split('.').last.toLowerCase();
      if (!['mp4', 'mov', 'avi', 'webm'].contains(extension)) {
        setState(() {
          _errorMessage = 'Invalid video format. Allowed: MP4, MOV, AVI, WebM';
          _isProcessing = false;
        });
        return;
      }

      // Initialize video player to get duration
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      final durationInSeconds = controller.value.duration.inSeconds;
      
      // Validate minimum duration (3 minutes = 180 seconds)
      if (durationInSeconds < 180) {
        controller.dispose();
        setState(() {
          _errorMessage = 'Video must be at least 3 minutes long';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _videoFile = file;
        _videoController?.dispose();
        _videoController = controller;
        _videoDuration = durationInSeconds;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate() || _videoFile == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      // Step 1: Get upload URL from backend
      setState(() => _uploadProgress = 0.1);
      final uploadUrlResponse = await _getUploadUrl();
      if (uploadUrlResponse == null) {
        throw Exception('Failed to get upload URL');
      }

      final uploadUrl = uploadUrlResponse['uploadUrl'] as String;
      final videoId = uploadUrlResponse['videoId'] as String;
      final storagePath = uploadUrlResponse['storagePath'] as String;

      // Step 2: Upload video to Firebase Storage
      setState(() => _uploadProgress = 0.2);
      await _uploadVideoToStorage(uploadUrl);

      // Step 3: Create video metadata
      setState(() => _uploadProgress = 0.9);
      await _createVideoMetadata(
        videoId: videoId,
        storagePath: storagePath,
      );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        Helpers.showSnackBar(context, 'Video uploaded successfully!');
        context.go(AppRoutes.feed);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: ${e.toString()}';
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<Map<String, dynamic>?> _getUploadUrl() async {
    try {
      final fileName = _videoFile!.path.split('/').last;
      final fileSize = await _videoFile!.length();
      final extension = fileName.split('.').last;
      
      String mimeType;
      switch (extension.toLowerCase()) {
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mov':
          mimeType = 'video/quicktime';
          break;
        case 'avi':
          mimeType = 'video/x-msvideo';
          break;
        case 'webm':
          mimeType = 'video/webm';
          break;
        default:
          mimeType = 'video/mp4';
      }

      final token = await _auth.currentUser?.getIdToken();
      
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.uploadUrl}',
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': mimeType,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Failed to get upload URL: $e');
      rethrow;
    }
  }

  Future<void> _uploadVideoToStorage(String uploadUrl) async {
    try {
      final bytes = await _videoFile!.readAsBytes();
      
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {
          'Content-Type': _getContentType(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to upload video: ${response.statusCode}');
      }

      setState(() => _uploadProgress = 0.8);
    } catch (e) {
      print('Video upload error: $e');
      rethrow;
    }
  }

  String _getContentType() {
    final extension = _videoFile!.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  Future<void> _createVideoMetadata({
    required String videoId,
    required String storagePath,
  }) async {
    try {
      final token = await _auth.currentUser?.getIdToken();

      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.videos}',
        data: {
          'videoId': videoId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory.name,
          'storagePath': storagePath,
          'duration': _videoDuration,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to create video metadata');
      }
    } catch (e) {
      print('Create metadata error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Upload Video',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: AppColors.textPrimary,
            size: AppDimensions.iconMedium,
          ),
          onPressed: _isUploading
              ? null
              : () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ),
      body: SafeArea(
        child: _isProcessing
            ? _buildProcessingState()
            : _isUploading
                ? _buildUploadingState()
                : _buildForm(),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.accentGreen,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Text(
            'Processing video...',
            style: TextStyle(
              fontSize: AppDimensions.fontMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: _uploadProgress,
                strokeWidth: 6,
                color: AppColors.accentGreen,
                backgroundColor: AppColors.borderLight,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXLarge),
            Text(
              'Uploading video...',
              style: TextStyle(
                fontSize: AppDimensions.fontLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: AppDimensions.fontHeading,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Please don\'t close this screen',
              style: TextStyle(
                fontSize: AppDimensions.fontSmall,
                color: AppColors.textSecondary,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: AppDimensions.iconMedium,
                        ),
                        const SizedBox(width: AppDimensions.paddingSmall),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSmall,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    CustomButton(
                      text: 'Retry',
                      onPressed: _handleUpload,
                      backgroundColor: AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: AppDimensions.iconMedium,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSmall,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
              ],
              
              // Video selection
              if (_videoFile == null)
                _buildVideoSelector()
              else
                _buildVideoPreview(),

              if (_videoFile != null) ...[
                const SizedBox(height: AppDimensions.paddingLarge),

                // Title
                CustomTextField(
                  label: 'Video Title',
                  controller: _titleController,
                  validator: Validators.validateVideoTitle,
                  prefixIcon: Icons.title,
                  maxLength: 60,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Description
                CustomTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  validator: Validators.validateDescription,
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Category selector
                _buildCategorySelector(),

                const SizedBox(height: AppDimensions.paddingLarge),

                // Upload button
                CustomButton(
                  text: 'Upload Video',
                  onPressed: _handleUpload,
                  icon: Icons.upload,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSelector() {
    return InkWell(
      onTap: _pickVideo,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: AppColors.borderMedium,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library_outlined,
                size: 48,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Select Video',
              style: TextStyle(
                fontSize: AppDimensions.fontLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
              child: Text(
                'MP4, MOV, AVI, WebM • Max 500MB • Min 3 minutes',
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLarge),
              ),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: AppDimensions.iconLarge,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _videoFile!.path.split('/').last,
                        style: TextStyle(
                          fontSize: AppDimensions.fontMedium,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDuration(_videoDuration)} • ${_formatFileSize(_videoFile!.lengthSync())}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: AppDimensions.iconMedium,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController?.dispose();
                      _videoController = null;
                      _videoFile = null;
                      _videoDuration = 0;
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: AppDimensions.fontMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Wrap(
          spacing: AppDimensions.paddingSmall,
          runSpacing: AppDimensions.paddingSmall,
          children: VideoCategory.values.map((category) {
            final isSelected = category == _selectedCategory;
            return FilterChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: AppColors.backgroundPrimary,
              selectedColor: AppColors.accentGreen.withOpacity(0.1),
              checkmarkColor: AppColors.accentGreen,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: AppDimensions.fontSmall,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.accentGreen
                    : AppColors.borderLight,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}