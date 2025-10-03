class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Endpoints
  static const String authBase = '/auth';
  static const String usersBase = '/users';
  static const String videosBase = '/videos';
  static const String sessionsBase = '/sessions';
  static const String reportsBase = '/reports';
  static const String moderationBase = '/moderation';

  // Auth Endpoints
  static const String register = '$authBase/register';
  static const String profile = '$authBase/profile';
  static const String deleteAccount = '$authBase/account';

  // User Endpoints
  static String userProfile(String userId) => '$usersBase/$userId';
  static String userVideos(String userId) => '$usersBase/$userId/videos';
  static String userFollowers(String userId) => '$usersBase/$userId/followers';
  static String userFollowing(String userId) => '$usersBase/$userId/following';
  static String followUser(String userId) => '$usersBase/$userId/follow';
  static const String savedVideos = '$usersBase/me/saved';
  static String saveVideo(String videoId) => '$usersBase/me/saved/$videoId';
  static const String watchHistory = '$usersBase/me/watch-history';

  // Video Endpoints
  static const String uploadUrl = '$videosBase/upload-url';
  static const String videos = videosBase;
  static String videoDetail(String videoId) => '$videosBase/$videoId';
  static const String feed = '$videosBase/feed';
  static const String followingFeed = '$videosBase/following';
  static String categoryFeed(String category) => '$videosBase/category/$category';
  static String videoView(String videoId) => '$videosBase/$videoId/view';
  static String videoComplete(String videoId) => '$videosBase/$videoId/complete';
  static String videoSkip(String videoId) => '$videosBase/$videoId/skip';

  // Session Endpoints
  static const String startSession = '$sessionsBase/start';
  static String checkIn(String sessionId) => '$sessionsBase/$sessionId/check-in';
  static String endSession(String sessionId) => '$sessionsBase/$sessionId/end';

  // Report Endpoints
  static const String createReport = reportsBase;
  static const String myReports = '$reportsBase/my-reports';
}