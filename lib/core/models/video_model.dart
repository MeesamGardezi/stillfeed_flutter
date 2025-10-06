class Video {
  final String videoId;
  final String title;
  final String description;
  final String category;
  final String videoUrl;
  final String thumbnailUrl;
  final int duration;
  final String uploaderId;
  final String uploaderName;
  final String uploaderProfilePic;
  final int viewCount;
  final int completionCount;
  final int skipCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSaved;

  Video({
    required this.videoId,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.uploaderId,
    required this.uploaderName,
    required this.uploaderProfilePic,
    required this.viewCount,
    required this.completionCount,
    required this.skipCount,
    required this.createdAt,
    required this.updatedAt,
    this.isSaved = false,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      duration: json['duration'] ?? 0,
      uploaderId: json['uploaderId'] ?? '',
      uploaderName: json['uploaderName'] ?? '',
      uploaderProfilePic: json['uploaderProfilePic'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      completionCount: json['completionCount'] ?? 0,
      skipCount: json['skipCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : DateTime.fromMillisecondsSinceEpoch(
                  json['createdAt']['_seconds'] * 1000))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'])
              : DateTime.fromMillisecondsSinceEpoch(
                  json['updatedAt']['_seconds'] * 1000))
          : DateTime.now(),
      isSaved: json['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'category': category,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'uploaderProfilePic': uploaderProfilePic,
      'viewCount': viewCount,
      'completionCount': completionCount,
      'skipCount': skipCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSaved': isSaved,
    };
  }

  Video copyWith({
    String? videoId,
    String? title,
    String? description,
    String? category,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
    String? uploaderId,
    String? uploaderName,
    String? uploaderProfilePic,
    int? viewCount,
    int? completionCount,
    int? skipCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSaved,
  }) {
    return Video(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      uploaderProfilePic: uploaderProfilePic ?? this.uploaderProfilePic,
      viewCount: viewCount ?? this.viewCount,
      completionCount: completionCount ?? this.completionCount,
      skipCount: skipCount ?? this.skipCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int totalPages;
  final int totalVideos;

  Pagination({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.totalVideos,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
      'totalVideos': totalVideos,
    };
  }
}

class VideoFeedResponse {
  final List<Video> videos;
  final Pagination pagination;

  VideoFeedResponse({
    required this.videos,
    required this.pagination,
  });

  factory VideoFeedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> videosJson = json['videos'] ?? [];
    final List<Video> videos = videosJson
        .map((videoJson) => Video.fromJson(videoJson as Map<String, dynamic>))
        .toList();

    return VideoFeedResponse(
      videos: videos,
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] ?? json['error']?['message'],
    );
  }
}