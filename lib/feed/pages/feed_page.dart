import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/models/video_model.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/formatters.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final VideoService _videoService = VideoService();
  final ValueNotifier<List<Video>> _videosNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _videosNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _videosNotifier.value = [];
    }

    _isLoadingNotifier.value = true;
    _errorNotifier.value = null;

    try {
      final response = await _videoService.getFeed(
        page: _currentPage,
        limit: 20,
      );

      if (response.success && response.data != null) {
        final newVideos = response.data!.videos;
        
        if (refresh) {
          _videosNotifier.value = newVideos;
        } else {
          _videosNotifier.value = [..._videosNotifier.value, ...newVideos];
        }

        _hasMore = response.data!.pagination.page < 
                   response.data!.pagination.totalPages;
      } else {
        _errorNotifier.value = response.message ?? 'Failed to load videos';
      }
    } catch (e) {
      _errorNotifier.value = e.toString();
    } finally {
      _isLoadingNotifier.value = false;
      _isLoadingMore = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _isLoadingMore = true;
        _currentPage++;
        _loadVideos();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadVideos(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'For You',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading && _videosNotifier.value.isEmpty) {
            return _buildLoadingState();
          }

          return ValueListenableBuilder<String?>(
            valueListenable: _errorNotifier,
            builder: (context, error, child) {
              if (error != null && _videosNotifier.value.isEmpty) {
                return _buildErrorState(error);
              }

              return ValueListenableBuilder<List<Video>>(
                valueListenable: _videosNotifier,
                builder: (context, videos, child) {
                  if (videos.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.accentGreen,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingSmall,
                      ),
                      itemCount: videos.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == videos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingLarge),
                              child: CircularProgressIndicator(
                                color: AppColors.accentGreen,
                              ),
                            ),
                          );
                        }
                        return YouTubeStyleVideoCard(video: videos[index]);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      itemCount: 5,
      itemBuilder: (context, index) => const VideoCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library_outlined,
                size: 56,
                color: AppColors.accentGreen.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'No Videos Yet',
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Be the first to share mindful content',
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              error,
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton(
              onPressed: () => _loadVideos(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.textOnAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FOLLOWING FEED PAGE
// ============================================================================

class FollowingFeedPage extends StatefulWidget {
  const FollowingFeedPage({super.key});

  @override
  State<FollowingFeedPage> createState() => _FollowingFeedPageState();
}

class _FollowingFeedPageState extends State<FollowingFeedPage> {
  final VideoService _videoService = VideoService();
  final ValueNotifier<List<Video>> _videosNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _videosNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _videosNotifier.value = [];
    }

    _isLoadingNotifier.value = true;
    _errorNotifier.value = null;

    try {
      final response = await _videoService.getFollowingFeed(
        page: _currentPage,
        limit: 20,
      );

      if (response.success && response.data != null) {
        final newVideos = response.data!.videos;
        
        if (refresh) {
          _videosNotifier.value = newVideos;
        } else {
          _videosNotifier.value = [..._videosNotifier.value, ...newVideos];
        }

        _hasMore = response.data!.pagination.page < 
                   response.data!.pagination.totalPages;
      } else {
        _errorNotifier.value = response.message ?? 'Failed to load videos';
      }
    } catch (e) {
      _errorNotifier.value = e.toString();
    } finally {
      _isLoadingNotifier.value = false;
      _isLoadingMore = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _isLoadingMore = true;
        _currentPage++;
        _loadVideos();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadVideos(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Following',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading && _videosNotifier.value.isEmpty) {
            return _buildLoadingState();
          }

          return ValueListenableBuilder<String?>(
            valueListenable: _errorNotifier,
            builder: (context, error, child) {
              if (error != null && _videosNotifier.value.isEmpty) {
                return _buildErrorState(error);
              }

              return ValueListenableBuilder<List<Video>>(
                valueListenable: _videosNotifier,
                builder: (context, videos, child) {
                  if (videos.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.accentGreen,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingSmall,
                      ),
                      itemCount: videos.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == videos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingLarge),
                              child: CircularProgressIndicator(
                                color: AppColors.accentGreen,
                              ),
                            ),
                          );
                        }
                        return YouTubeStyleVideoCard(video: videos[index]);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      itemCount: 5,
      itemBuilder: (context, index) => const VideoCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 56,
                color: AppColors.accentGreen.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'No Videos Yet',
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Follow creators to see their videos here',
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              error,
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton(
              onPressed: () => _loadVideos(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.textOnAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// YOUTUBE-STYLE VIDEO CARD
// ============================================================================

class YouTubeStyleVideoCard extends StatelessWidget {
  final Video video;

  const YouTubeStyleVideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // FIXED: Use GoRouter navigation with extra parameter
        context.push(AppRoutes.videoPlayer, extra: video);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
        color: AppColors.backgroundPrimary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with duration badge
            _buildThumbnail(),
            // Video info
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  _buildProfilePicture(context),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  // Video details
                  Expanded(
                    child: _buildVideoDetails(),
                  ),
                  // More options button
                  _buildMoreButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: video.thumbnailUrl.isNotEmpty
              ? Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.backgroundSecondary,
                      child: Center(
                        child: Icon(
                          Icons.video_library_outlined,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.backgroundSecondary,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  color: AppColors.backgroundSecondary,
                  child: Center(
                    child: Icon(
                      Icons.video_library_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ),
        ),
        // Duration badge
        if (video.duration > 0)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                Formatters.formatSeconds(video.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to uploader's profile
        // context.push('${AppRoutes.otherProfile}/${video.uploaderId}');
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.accentGreen.withOpacity(0.1),
        backgroundImage: video.uploaderProfilePic.isNotEmpty
            ? NetworkImage(video.uploaderProfilePic)
            : null,
        child: video.uploaderProfilePic.isEmpty
            ? Text(
                video.uploaderName.isNotEmpty
                    ? video.uploaderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: AppDimensions.fontSmall,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildVideoDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          video.title,
          style: TextStyle(
            fontSize: AppDimensions.fontMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Uploader and metadata
        Text(
          video.uploaderName,
          style: TextStyle(
            fontSize: AppDimensions.fontSmall,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Views and time
        Text(
          '${_formatViews(video.viewCount)} views • ${Formatters.formatTimeAgo(video.createdAt)}',
          style: TextStyle(
            fontSize: AppDimensions.fontSmall,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.more_vert,
        size: AppDimensions.iconMedium,
        color: AppColors.textSecondary,
      ),
      onPressed: () {
        _showVideoOptions(context);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showVideoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                video.isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: AppColors.textPrimary,
              ),
              title: Text(
                video.isSaved ? 'Remove from saved' : 'Save video',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontMedium,
                ),
              ),
              onTap: () {
                // TODO: Implement save/unsave
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: AppColors.textPrimary,
              ),
              title: Text(
                'Share',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontMedium,
                ),
              ),
              onTap: () {
                // TODO: Implement share
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.report_outlined,
                color: AppColors.error,
              ),
              title: Text(
                'Report',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: AppDimensions.fontMedium,
                ),
              ),
              onTap: () {
                // TODO: Implement report
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
}

// ============================================================================
// VIDEO CARD SKELETON (Loading state)
// ============================================================================

class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      color: AppColors.backgroundPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.backgroundSecondary,
            ),
          ),
          // Info skeleton
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture skeleton
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.backgroundSecondary,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                // Details skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 150,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 10,
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(4),
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

// ============================================================================
// CATEGORY FEED PAGE
// ============================================================================

class CategoryFeedPage extends StatefulWidget {
  final String category;

  const CategoryFeedPage({super.key, required this.category});

  @override
  State<CategoryFeedPage> createState() => _CategoryFeedPageState();
}

class _CategoryFeedPageState extends State<CategoryFeedPage> {
  final VideoService _videoService = VideoService();
  final ValueNotifier<List<Video>> _videosNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _videosNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _videosNotifier.value = [];
    }

    _isLoadingNotifier.value = true;
    _errorNotifier.value = null;

    try {
      final response = await _videoService.getCategoryFeed(
        category: widget.category.toLowerCase(),
        page: _currentPage,
        limit: 20,
      );

      if (response.success && response.data != null) {
        final newVideos = response.data!.videos;
        
        if (refresh) {
          _videosNotifier.value = newVideos;
        } else {
          _videosNotifier.value = [..._videosNotifier.value, ...newVideos];
        }

        _hasMore = response.data!.pagination.page < 
                   response.data!.pagination.totalPages;
      } else {
        _errorNotifier.value = response.message ?? 'Failed to load videos';
      }
    } catch (e) {
      _errorNotifier.value = e.toString();
    } finally {
      _isLoadingNotifier.value = false;
      _isLoadingMore = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _isLoadingMore = true;
        _currentPage++;
        _loadVideos();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadVideos(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          widget.category,
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: AppDimensions.iconMedium,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading && _videosNotifier.value.isEmpty) {
            return _buildLoadingState();
          }

          return ValueListenableBuilder<String?>(
            valueListenable: _errorNotifier,
            builder: (context, error, child) {
              if (error != null && _videosNotifier.value.isEmpty) {
                return _buildErrorState(error);
              }

              return ValueListenableBuilder<List<Video>>(
                valueListenable: _videosNotifier,
                builder: (context, videos, child) {
                  if (videos.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.accentGreen,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingSmall,
                      ),
                      itemCount: videos.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == videos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingLarge),
                              child: CircularProgressIndicator(
                                color: AppColors.accentGreen,
                              ),
                            ),
                          );
                        }
                        return YouTubeStyleVideoCard(video: videos[index]);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      itemCount: 5,
      itemBuilder: (context, index) => const VideoCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 56,
                color: AppColors.accentGreen.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'No Videos Yet',
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'No videos in ${widget.category} category yet',
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              error,
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton(
              onPressed: () => _loadVideos(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.textOnAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}