class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Main Routes
  static const String feed = '/';
  static const String followingFeed = '/following-feed';
  static const String categoryFeed = '/category/:category';

  // Video Routes
  static const String videoPlayer = '/video/:videoId';
  static const String uploadVideo = '/upload';
  static const String videoDetails = '/video/:videoId/details';

  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String otherProfile = '/user/:userId';
  static const String savedVideos = '/saved';
  static const String followingList = '/following';

  // Settings
  static const String settings = '/settings';

  // Route Names (for navigation)
  static const String loginName = 'login';
  static const String signupName = 'signup';
  static const String forgotPasswordName = 'forgotPassword';
  static const String feedName = 'feed';
  static const String followingFeedName = 'followingFeed';
  static const String categoryFeedName = 'categoryFeed';
  static const String videoPlayerName = 'videoPlayer';
  static const String uploadVideoName = 'uploadVideo';
  static const String videoDetailsName = 'videoDetails';
  static const String profileName = 'profile';
  static const String editProfileName = 'editProfile';
  static const String otherProfileName = 'otherProfile';
  static const String savedVideosName = 'savedVideos';
  static const String followingListName = 'followingList';
  static const String settingsName = 'settings';
}