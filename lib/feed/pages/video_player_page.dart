import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/video_model.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/formatters.dart';

class VideoPlayerPage extends StatefulWidget {
  final Video video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  final VideoService _videoService = VideoService();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool _isPlaying = false;
  bool _isSaved = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSubscribed = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isTheaterMode = false;
  bool _showMoreDesc = false;
  bool _showVolumeSlider = false;

  double _volume = 1.0;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.video.isSaved;
    _initializePlayer();
    _trackView();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (widget.video.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );

      await _controller!.initialize();

      _controller!.addListener(() {
        if (mounted) {
          final isPlaying = _controller!.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _volume = _controller!.value.volume;
        });
        _controller!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _trackView() async {
    try {
      await _videoService.trackView(widget.video.videoId);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _toggleSave() async {
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await _videoService.saveVideo(widget.video.videoId);
      } else {
        await _videoService.unsaveVideo(widget.video.videoId);
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        _isTheaterMode = false;
      }
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleTheaterMode() {
    setState(() {
      _isTheaterMode = !_isTheaterMode;
    });
  }

  void _changeVolume(double newVolume) {
    if (_controller == null) return;
    setState(() {
      _volume = newVolume.clamp(0.0, 1.0);
      _controller!.setVolume(_volume);
    });
  }

  void _showControlsTemporary() {
    setState(() {
      _showControls = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (_isPlaying && mounted) {
        setState(() {
          _showControls = false;
          _showVolumeSlider = false;
        });
      }
    });
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(0)}K';
    }
    return views.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildFullscreenPlayer(),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoPlayerContainer(),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVideoInfo(),
                          const SizedBox(height: 16),
                          _buildActionBar(),
                          const Divider(height: 32),
                          _buildChannelInfo(),
                          if (widget.video.description.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildDescription(),
                          ],
                          const SizedBox(height: 32),
                          _buildComments(),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 402,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildRelatedVideos(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildVideoPlayerContainer(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVideoInfo(),
                      const SizedBox(height: 12),
                      _buildActionBar(),
                      const Divider(height: 24),
                      _buildChannelInfo(),
                      if (widget.video.description.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildDescription(),
                      ],
                      const Divider(height: 24),
                      _buildComments(),
                      const Divider(height: 24),
                    ],
                  ),
                ),
                _buildRelatedVideos(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayerContainer() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    // Calculate proper height based on mode
    BoxConstraints containerConstraints;

    if (_isTheaterMode) {
      // Theater mode: Use 85% of screen height for a larger view
      final theaterHeight = screenHeight * 0.85;
      containerConstraints = BoxConstraints(
        minHeight: theaterHeight,
        maxHeight: theaterHeight,
      );
    } else {
      // Normal mode: Use aspect ratio with reasonable max height
      final normalMaxHeight = screenHeight * 0.56;
      final aspectRatioHeight = screenWidth * 9 / 16;

      containerConstraints = BoxConstraints(
        minHeight: 200, // Minimum reasonable height
        maxHeight: normalMaxHeight,
      );
    }

    return Stack(
      children: [
        Container(
          color: Colors.black,
          constraints: containerConstraints,
          width: double.infinity,
          child: _buildVideoPlayerWidget(),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayerWidget() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporary,
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [VideoPlayer(_controller!), _buildYouTubeControls()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // Center play/pause button
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFFF0000),
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),

                // Control buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      // Left side controls
                      _buildControlPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildControlButton(
                              icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                              onTap: _togglePlayPause,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildControlPill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Right side controls
                      _buildControlPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Volume control
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _buildControlButton(
                                  icon: _volume == 0
                                      ? Icons.volume_off
                                      : _volume < 0.5
                                      ? Icons.volume_down
                                      : Icons.volume_up,
                                  onTap: () {
                                    setState(() {
                                      _showVolumeSlider = !_showVolumeSlider;
                                    });
                                    _showControlsTemporary();
                                  },
                                ),
                                if (_showVolumeSlider)
                                  Positioned(
                                    bottom: 48,
                                    left: -8,
                                    child: _buildVolumeSlider(),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 4),
                            _buildControlButton(
                              icon: Icons.settings,
                              onTap: () {
                                // Settings menu
                              },
                            ),

                            const SizedBox(width: 4),
                            _buildControlButton(
                              icon: _isTheaterMode
                                  ? Icons.fullscreen_exit
                                  : Icons.crop_16_9,
                              onTap: _toggleTheaterMode,
                            ),

                            const SizedBox(width: 4),
                            _buildControlButton(
                              icon: Icons.fullscreen,
                              onTap: _toggleFullscreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPill({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 20,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Container(
      height: 120,
      width: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RotatedBox(
        quarterTurns: -1,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
          ),
          child: Slider(
            value: _volume,
            onChanged: _changeVolume,
            min: 0.0,
            max: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.video.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_formatViews(widget.video.viewCount)} views • ${Formatters.formatTimeAgo(widget.video.createdAt)}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: 'Like',
            isActive: _isLiked,
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
                if (_isLiked) _isDisliked = false;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
            label: 'Dislike',
            isActive: _isDisliked,
            onTap: () {
              setState(() {
                _isDisliked = !_isDisliked;
                if (_isDisliked) _isLiked = false;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(icon: Icons.share, label: 'Share', onTap: () {}),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _isSaved ? Icons.playlist_add_check : Icons.playlist_add,
            label: 'Save',
            isActive: _isSaved,
            onTap: _toggleSave,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.blue : Colors.black87,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.blue : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfo() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.video.uploaderProfilePic.isNotEmpty
                ? NetworkImage(widget.video.uploaderProfilePic)
                : null,
            child: widget.video.uploaderProfilePic.isEmpty
                ? Text(
                    widget.video.uploaderName.isNotEmpty
                        ? widget.video.uploaderName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.video.uploaderName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '1.2M subscribers',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isSubscribed = !_isSubscribed;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubscribed ? Colors.grey[200] : Colors.red,
              foregroundColor: _isSubscribed ? Colors.black87 : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(100, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isSubscribed ? 'Subscribed' : 'Subscribe',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final description = widget.video.description;
    if (description.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(fontSize: 14),
            maxLines: _showMoreDesc ? null : 3,
            overflow: _showMoreDesc
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (description.length > 150) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMoreDesc = !_showMoreDesc;
                });
              },
              child: Text(
                _showMoreDesc ? 'Show less' : '...more',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.comments_disabled_outlined,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Comments are turned off',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Related Videos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRelatedVideoItem(
              title: 'Sample Video ${index + 1}',
              channel: 'Channel ${index + 1}',
              views: '${100 + index * 50}K views',
              time: '${index + 1} days ago',
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRelatedVideoItem({
    required String title,
    required String channel,
    required String views,
    required String time,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 168,
              height: 94,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.grey[600],
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '$views • $time',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenPlayer() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporary,
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [VideoPlayer(_controller!), _buildFullscreenControls()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // Center play button
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _toggleFullscreen,
                icon: const Icon(
                  Icons.fullscreen_exit,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFFF0000),
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      _buildControlPill(
                        child: _buildControlButton(
                          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                          onTap: _togglePlayPause,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildControlPill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildControlPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _buildControlButton(
                                  icon: _volume == 0
                                      ? Icons.volume_off
                                      : _volume < 0.5
                                      ? Icons.volume_down
                                      : Icons.volume_up,
                                  onTap: () {
                                    setState(() {
                                      _showVolumeSlider = !_showVolumeSlider;
                                    });
                                    _showControlsTemporary();
                                  },
                                ),
                                if (_showVolumeSlider)
                                  Positioned(
                                    bottom: 52,
                                    left: -8,
                                    child: _buildVolumeSlider(),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            _buildControlButton(
                              icon: Icons.settings,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
