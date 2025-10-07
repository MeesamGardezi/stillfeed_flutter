import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/api_config.dart';
import '../models/video_model.dart';

class VideoService {
  final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VideoService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                sendTimeout: ApiConfig.sendTimeout,
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Add auth token if user is logged in
            final user = _auth.currentUser;
            if (user != null) {
              // Retry token fetch with small delays
              String? token;
              for (int attempt = 0; attempt < 3; attempt++) {
                try {
                  token = await user.getIdToken(attempt == 0);
                  if (token != null && token.isNotEmpty) {
                    print('VideoService: ✓ Token fetched on attempt ${attempt + 1} for ${options.path}');
                    break;
                  }
                } catch (e) {
                  print('VideoService: ✗ Token fetch attempt ${attempt + 1} failed: $e');
                  if (attempt < 2) {
                    await Future.delayed(Duration(milliseconds: 100 + (attempt * 200)));
                  }
                }
              }
              
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              } else {
                print('VideoService: ⚠ No token available for request: ${options.path}');
              }
            } else {
              print('VideoService: ⚠ No user logged in for request: ${options.path}');
            }
          } catch (e) {
            print('VideoService: ✗ Error in request interceptor: $e');
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('VideoService: ✗ Request error for ${error.requestOptions.path}:');
          print('  Type: ${error.type}');
          print('  Message: ${error.message}');
          if (error.response != null) {
            print('  Status: ${error.response?.statusCode}');
            print('  Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Get feed videos (For You feed)
  Future<ApiResponse<VideoFeedResponse>> getFeed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('VideoService: Fetching feed (page: $page, limit: $limit)');
      final response = await _dio.get(
        ApiConfig.feed,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      print('VideoService: ✓ Feed fetched successfully');
      return ApiResponse<VideoFeedResponse>.fromJson(
        response.data,
        (data) => VideoFeedResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('VideoService: ✗ Feed fetch error: ${e.type}');
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      print('VideoService: ✗ Unexpected error: $e');
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get following feed (videos from followed users)
  Future<ApiResponse<VideoFeedResponse>> getFollowingFeed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('VideoService: Fetching following feed (page: $page, limit: $limit)');
      final response = await _dio.get(
        ApiConfig.followingFeed,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      print('VideoService: ✓ Following feed fetched successfully');
      return ApiResponse<VideoFeedResponse>.fromJson(
        response.data,
        (data) => VideoFeedResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('VideoService: ✗ Following feed fetch error: ${e.type}');
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      print('VideoService: ✗ Unexpected error: $e');
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get category feed
  Future<ApiResponse<VideoFeedResponse>> getCategoryFeed({
    required String category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.categoryFeed(category),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return ApiResponse<VideoFeedResponse>.fromJson(
        response.data,
        (data) => VideoFeedResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get single video by ID
  Future<ApiResponse<Video>> getVideoById(String videoId) async {
    try {
      final response = await _dio.get(ApiConfig.videoDetail(videoId));

      return ApiResponse<Video>.fromJson(
        response.data,
        (data) => Video.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<Video>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<Video>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get user's uploaded videos
  Future<ApiResponse<VideoFeedResponse>> getUserVideos({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.userVideos(userId),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return ApiResponse<VideoFeedResponse>.fromJson(
        response.data,
        (data) => VideoFeedResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Track video view
  Future<ApiResponse<void>> trackView(String videoId) async {
    try {
      await _dio.post(ApiConfig.videoView(videoId));
      return ApiResponse<void>(success: true);
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Track video completion
  Future<ApiResponse<void>> trackCompletion({
    required String videoId,
    int? watchDuration,
  }) async {
    try {
      await _dio.post(
        ApiConfig.videoComplete(videoId),
        data: {
          if (watchDuration != null) 'watchDuration': watchDuration,
        },
      );
      return ApiResponse<void>(success: true);
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Track video skip
  Future<ApiResponse<void>> trackSkip({
    required String videoId,
    int? watchDuration,
  }) async {
    try {
      await _dio.post(
        ApiConfig.videoSkip(videoId),
        data: {
          if (watchDuration != null) 'watchDuration': watchDuration,
        },
      );
      return ApiResponse<void>(success: true);
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Save video
  Future<ApiResponse<void>> saveVideo(String videoId) async {
    try {
      await _dio.post(ApiConfig.saveVideo(videoId));
      return ApiResponse<void>(success: true, message: 'Video saved');
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Unsave video
  Future<ApiResponse<void>> unsaveVideo(String videoId) async {
    try {
      await _dio.delete(ApiConfig.saveVideo(videoId));
      return ApiResponse<void>(success: true, message: 'Video unsaved');
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get saved videos
  Future<ApiResponse<VideoFeedResponse>> getSavedVideos({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.savedVideos,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return ApiResponse<VideoFeedResponse>.fromJson(
        response.data,
        (data) => VideoFeedResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<VideoFeedResponse>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get upload URL for video
  Future<ApiResponse<Map<String, dynamic>>> getUploadUrl({
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.uploadUrl,
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': mimeType,
        },
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Create video metadata
  Future<ApiResponse<Video>> createVideo({
    required String videoId,
    required String title,
    required String category,
    required String storagePath,
    String? description,
    String? thumbnailUrl,
    int? duration,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.videos,
        data: {
          'videoId': videoId,
          'title': title,
          'category': category,
          'storagePath': storagePath,
          if (description != null) 'description': description,
          if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
          if (duration != null) 'duration': duration,
        },
      );

      return ApiResponse<Video>.fromJson(
        response.data,
        (data) => Video.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<Video>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<Video>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Update video metadata
  Future<ApiResponse<Video>> updateVideo({
    required String videoId,
    String? title,
    String? description,
    String? category,
    String? thumbnailUrl,
  }) async {
    try {
      final response = await _dio.put(
        ApiConfig.videoDetail(videoId),
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (category != null) 'category': category,
          if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        },
      );

      return ApiResponse<Video>.fromJson(
        response.data,
        (data) => Video.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<Video>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<Video>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Delete video
  Future<ApiResponse<void>> deleteVideo(String videoId) async {
    try {
      await _dio.delete(ApiConfig.videoDetail(videoId));
      return ApiResponse<void>(
        success: true,
        message: 'Video deleted successfully',
      );
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Handle Dio errors
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        // Try to extract error message from response
        if (data != null && data is Map<String, dynamic>) {
          if (data['error'] != null && data['error']['message'] != null) {
            return data['error']['message'] as String;
          }
          if (data['message'] != null) {
            return data['message'] as String;
          }
        }

        switch (statusCode) {
          case 400:
            return 'Bad request. Please check your input.';
          case 401:
            return 'Unauthorized. Please log in again.';
          case 403:
            return 'Forbidden. You don\'t have permission to perform this action.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'An error occurred. Please try again.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error.';
      default:
        return 'An unexpected error occurred. Please check your internet connection.';
    }
  }
}