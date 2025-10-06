class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? bio;
  final String? profilePicUrl;
  final DateTime createdAt;
  final int strikeCount;
  final int totalUploads;
  final double impactScore;
  final int followerCount;
  final int followingCount;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.bio,
    this.profilePicUrl,
    required this.createdAt,
    required this.strikeCount,
    required this.totalUploads,
    required this.impactScore,
    required this.followerCount,
    required this.followingCount,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(json['createdAt']['_seconds'] * 1000),
      strikeCount: json['strikeCount'] as int? ?? 0,
      totalUploads: json['totalUploads'] as int? ?? 0,
      impactScore: (json['impactScore'] as num?)?.toDouble() ?? 0.0,
      followerCount: json['followerCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? bio,
    String? profilePicUrl,
    DateTime? createdAt,
    int? strikeCount,
    int? totalUploads,
    double? impactScore,
    int? followerCount,
    int? followingCount,
    bool? isAdmin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      createdAt: createdAt ?? this.createdAt,
      strikeCount: strikeCount ?? this.strikeCount,
      totalUploads: totalUploads ?? this.totalUploads,
      impactScore: impactScore ?? this.impactScore,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}