import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  Uint8List? _videoBytes;
  String? _videoFileName;
  VideoPlayerController? _videoController;
  VideoCategory _selectedCategory = VideoCategory.nature;
  
  bool _isProcessing = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  int _videoDuration = 0;
  int _videoFileSize = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final pickedFile = result.files.first;
      
      final fileSize = pickedFile.size;
      final fileSizeMB = fileSize / (1024 * 1024);
      
      if (fileSizeMB > 500) {
        setState(() {
          _errorMessage = 'Video file size exceeds 500MB limit';
          _isProcessing = false;
        });
        return;
      }

      final extension = pickedFile.extension?.toLowerCase() ?? '';
      if (!['mp4', 'mov', 'avi', 'webm'].contains(extension)) {
        setState(() {
          _errorMessage = 'Invalid video format. Allowed: MP4, MOV, AVI, WebM';
          _isProcessing = false;
        });
        return;
      }

      _videoFileName = pickedFile.name;
      _videoFileSize = pickedFile.size;

      if (kIsWeb) {
        _videoBytes = pickedFile.bytes;
        
        if (_videoBytes == null) {
          setState(() {
            _errorMessage = 'Failed to read video file';
            _isProcessing = false;
          });
          return;
        }

        final estimatedMinutes = (fileSizeMB / 8).ceil();
        _videoDuration = estimatedMinutes * 60;
        
        if (estimatedMinutes < 3) {
          setState(() {
            _errorMessage = 'Video appears too short. Min 3 minutes required.';
            _isProcessing = false;
            _videoBytes = null;
          });
          return;
        }

        setState(() => _isProcessing = false);
        
      } else {
        final file = File(pickedFile.path!);
        _videoFile = file;
        
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        
        final durationInSeconds = controller.value.duration.inSeconds;
        
        if (durationInSeconds < 180) {
          controller.dispose();
          setState(() {
            _errorMessage = 'Video must be at least 3 minutes long';
            _isProcessing = false;
            _videoFile = null;
          });
          return;
        }

        setState(() {
          _videoController?.dispose();
          _videoController = controller;
          _videoDuration = durationInSeconds;
          _isProcessing = false;
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (kIsWeb && _videoBytes == null) {
      setState(() => _errorMessage = 'Please select a video first');
      return;
    }
    
    if (!kIsWeb && _videoFile == null) {
      setState(() => _errorMessage = 'Please select a video first');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    String? videoUrl;
    String? storagePath;

    try {
      // Step 1: Generate storage path and video ID
      final userId = _auth.currentUser!.uid;
      final videoId = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = _videoFileName!.split('.').last;
      storagePath = 'videos/$userId/$videoId.$extension';

      setState(() => _uploadProgress = 0.1);

      // Step 2: Upload to Firebase Storage
      print('Uploading to Firebase Storage: $storagePath');
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(
          _videoBytes!,
          SettableMetadata(contentType: _getContentType()),
        );
      } else {
        uploadTask = storageRef.putFile(
          _videoFile!,
          SettableMetadata(contentType: _getContentType()),
        );
      }

      // Listen to progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = 0.1 + (progress * 0.7); // 10% to 80%
        });
      });

      // Wait for upload
      final snapshot = await uploadTask;
      print('Upload complete! Getting download URL...');

      // Step 3: Get download URL
      videoUrl = await snapshot.ref.getDownloadURL();
      print('Download URL: $videoUrl');

      setState(() => _uploadProgress = 0.85);

      // Step 4: Create metadata in backend
      print('Creating metadata in backend...');
      await _createVideoMetadata(
        videoUrl: videoUrl,
        storagePath: storagePath,
      );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        Helpers.showSnackBar(context, 'Video uploaded successfully!');
        context.go(AppRoutes.feed);
      }
    } catch (e) {
      print('Upload failed: $e');
      
      // Clean up on error - delete the uploaded file if it exists
      if (storagePath != null) {
        try {
          await FirebaseStorage.instance.ref().child(storagePath).delete();
        } catch (deleteError) {
          print('Could not delete file: $deleteError');
        }
      }
      
      setState(() {
        _errorMessage = 'Upload failed: ${e.toString()}';
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  String _getContentType() {
    final extension = (_videoFileName ?? 'video.mp4').split('.').last.toLowerCase();
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
    required String videoUrl,
    required String storagePath,
  }) async {
    try {
      final token = await _auth.currentUser?.getIdToken();

      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.videos}',
        data: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory.name,
          'videoUrl': videoUrl,
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
      
      print('Metadata created successfully');
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
          onPressed: _isUploading ? null : () => context.pop(),
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
          CircularProgressIndicator(color: AppColors.accentGreen),
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
    final hasVideo = kIsWeb ? _videoBytes != null : _videoFile != null;
    
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
              
              if (!hasVideo)
                _buildVideoSelector()
              else
                _buildVideoInfo(),

              if (hasVideo) ...[
                const SizedBox(height: AppDimensions.paddingLarge),
                CustomTextField(
                  label: 'Video Title',
                  controller: _titleController,
                  validator: Validators.validateVideoTitle,
                  prefixIcon: Icons.title,
                  maxLength: 60,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                CustomTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  validator: Validators.validateDescription,
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildCategorySelector(),
                const SizedBox(height: AppDimensions.paddingLarge),
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
          border: Border.all(color: AppColors.borderMedium, width: 2),
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

  Widget _buildVideoInfo() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!kIsWeb && _videoController != null && _videoController!.value.isInitialized)
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
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: AppDimensions.iconLarge,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying 
                            ? _videoController!.pause() 
                            : _videoController!.play();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          
          if (kIsWeb)
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLarge),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_file,
                      size: 48,
                      color: AppColors.accentGreen.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      'Video Selected',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMedium,
                        color: AppColors.textSecondary,
                      ),
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
                        _videoFileName ?? 'video.mp4',
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
                        '${_formatDuration(_videoDuration)} • ${_formatFileSize(_videoFileSize)}',
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
                      _videoBytes = null;
                      _videoFileName = null;
                      _videoDuration = 0;
                      _videoFileSize = 0;
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
              onSelected: (selected) => setState(() => _selectedCategory = category),
              backgroundColor: AppColors.backgroundPrimary,
              selectedColor: AppColors.accentGreen.withOpacity(0.1),
              checkmarkColor: AppColors.accentGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accentGreen : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: AppDimensions.fontSmall,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.accentGreen : AppColors.borderLight,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}