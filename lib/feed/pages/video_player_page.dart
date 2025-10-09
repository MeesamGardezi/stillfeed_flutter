import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/models/video_model.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/formatters.dart';

class VideoPlayerPage extends StatefulWidget {
  final Video video;

  const VideoPlayerPage({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  final VideoService _videoService = VideoService();
  bool _isInitializing = true;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isSaved = false;
  bool _controlsVisible = true;
  int _watchStartTime = 0;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.video.isSaved;
    _initializeVideo();
    _trackView();
    _watchStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void dispose() {
    _trackCompletion();
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );

      await _controller!.initialize();
      
      _controller!.addListener(() {
        if (_controller!.value.isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });

      setState(() {
        _isInitializing = false;
      });

      // Auto-play
      await _controller!.play();
      setState(() {
        _isPlaying = true;
      });

      // Hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() {
            _controlsVisible = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isInitializing = false;
      });
      print('Error initializing video: $e');
    }
  }

  Future<void> _trackView() async {
    await _videoService.trackView(widget.video.videoId);
  }

  Future<void> _trackCompletion() async {
    if (_controller == null) return;
    
    final position = _controller!.value.position.inSeconds;
    final duration = _controller!.value.duration.inSeconds;
    
    if (duration > 0) {
      final watchedPercentage = (position / duration) * 100;
      final watchDuration = 
          (DateTime.now().millisecondsSinceEpoch - _watchStartTime) ~/ 1000;
      
      if (watchedPercentage > 80) {
        await _videoService.trackCompletion(
          videoId: widget.video.videoId,
          watchDuration: watchDuration,
        );
      } else if (watchedPercentage < 20) {
        await _videoService.trackSkip(
          videoId: widget.video.videoId,
          watchDuration: watchDuration,
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    setState(() {
      _isSaved = !_isSaved;
    });

    if (_isSaved) {
      await _videoService.saveVideo(widget.video.videoId);
    } else {
      await _videoService.unsaveVideo(widget.video.videoId);
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible && _isPlaying) {
      // Auto-hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() {
            _controlsVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGreen,
              ),
            )
          else if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load video',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: AppDimensions.fontLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_controller != null && _controller!.value.isInitialized)
            GestureDetector(
              onTap: _toggleControls,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),

          // Controls Overlay
          if (_controller != null && 
              _controller!.value.isInitialized && 
              _controlsVisible)
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Top Bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => context.pop(),
                              ),
                              Expanded(
                                child: Text(
                                  widget.video.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: AppDimensions.fontMedium,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isSaved 
                                      ? Icons.bookmark 
                                      : Icons.bookmark_border,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleSave,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Center Play/Pause Button
                    Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),

                    // Bottom Bar with Progress
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Video Info
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingLarge,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Uploader info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: 
                                            AppColors.accentGreen.withOpacity(0.2),
                                        backgroundImage: 
                                            widget.video.uploaderProfilePic.isNotEmpty
                                                ? NetworkImage(
                                                    widget.video.uploaderProfilePic)
                                                : null,
                                        child: widget.video.uploaderProfilePic.isEmpty
                                            ? Text(
                                                widget.video.uploaderName.isNotEmpty
                                                    ? widget.video.uploaderName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: AppDimensions.paddingSmall),
                                      Expanded(
                                        child: Text(
                                          widget.video.uploaderName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: AppDimensions.fontMedium,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimensions.paddingSmall),
                                  // Description
                                  if (widget.video.description.isNotEmpty)
                                    Text(
                                      widget.video.description,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: AppDimensions.fontSmall,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingMedium),
                            // Progress Bar
                            VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: AppColors.accentGreen,
                                bufferedColor: 
                                    AppColors.accentGreen.withOpacity(0.3),
                                backgroundColor: 
                                    Colors.white.withOpacity(0.2),
                              ),
                            ),
                            // Time display
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingLarge,
                                vertical: AppDimensions.paddingSmall,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.formatDuration(
                                        _controller!.value.position),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: AppDimensions.fontXSmall,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatDuration(
                                        _controller!.value.duration),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: AppDimensions.fontXSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}