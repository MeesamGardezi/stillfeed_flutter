import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../core/models/video_model.dart';
import '../../core/services/video_service.dart';

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
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGreen,
              ),
            );
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
                        vertical: AppDimensions.paddingMedium,
                      ),
                      itemCount: videos.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == videos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingMedium),
                              child: CircularProgressIndicator(
                                color: AppColors.accentGreen,
                              ),
                            ),
                          );
                        }
                        return VideoCard(video: videos[index]);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library_outlined,
                size: 48,
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
              size: 48,
              color: AppColors.textSecondary,
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
                foregroundColor: AppColors.backgroundPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
              child: const Text('Retry'),
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
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGreen,
              ),
            );
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
                        vertical: AppDimensions.paddingMedium,
                      ),
                      itemCount: videos.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == videos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingMedium),
                              child: CircularProgressIndicator(
                                color: AppColors.accentGreen,
                              ),
                            ),
                          );
                        }
                        return VideoCard(video: videos[index]);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
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
              size: 48,
              color: AppColors.textSecondary,
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
                foregroundColor: AppColors.backgroundPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
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
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGreen,
              ),
            );
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
                        vertical: AppDimensions.paddingMedium,
                      ),
                      itemCount: videos.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == videos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingMedium),
                              child: CircularProgressIndicator(
                                color: AppColors.accentGreen,
                              ),
                            ),
                          );
                        }
                        return VideoCard(video: videos[index]);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 48,
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
              size: 48,
              color: AppColors.textSecondary,
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
                foregroundColor: AppColors.backgroundPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VIDEO CARD WIDGET
// ============================================================================

class VideoCard extends StatelessWidget {
  final Video video;

  const VideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to video player
        Navigator.pushNamed(
          context,
          '/video-player',
          arguments: video,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusMedium),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: video.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.backgroundSecondary,
                            child: const Icon(
                              Icons.video_library_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.backgroundSecondary,
                        child: const Icon(
                          Icons.video_library_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            // Video info
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.title,
                    style: TextStyle(
                      fontSize: AppDimensions.fontMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (video.description.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      video.description,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingMedium),
                  // Uploader info and stats
                  Row(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.accentGreen.withOpacity(0.1),
                        backgroundImage: video.uploaderProfilePic.isNotEmpty
                            ? NetworkImage(video.uploaderProfilePic)
                            : null,
                        child: video.uploaderProfilePic.isEmpty
                            ? Text(
                                video.uploaderName.isNotEmpty
                                    ? video.uploaderName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      // Uploader name
                      Expanded(
                        child: Text(
                          video.uploaderName,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSmall,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // View count
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(video.viewCount),
                        style: TextStyle(
                          fontSize: AppDimensions.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}