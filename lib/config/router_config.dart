import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/pages/forgot_password_page.dart';
import '../auth/pages/login_page.dart';
import '../auth/pages/signup_page.dart';
import '../feed/pages/feed_page.dart';
import '../home/pages/main_layout_page.dart';
import 'routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.feed,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.feed;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: AppRoutes.signupName,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayoutPage(
            currentPath: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.feed,
            name: AppRoutes.feedName,
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const FeedPage()),
          ),
          GoRoute(
            path: AppRoutes.followingFeed,
            name: AppRoutes.followingFeedName,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const FollowingFeedPage(),
            ),
          ),
          //     GoRoute(
          //       path: AppRoutes.categoryFeed,
          //       name: AppRoutes.categoryFeedName,
          //       builder: (context, state) {
          //         final category = state.pathParameters['category']!;
          //         return CategoryFeedPage(category: category);
          //       },
          //     ),
          //     GoRoute(
          //       path: AppRoutes.savedVideos,
          //       name: AppRoutes.savedVideosName,
          //       pageBuilder: (context, state) => NoTransitionPage(
          //         key: state.pageKey,
          //         child: const SavedVideosPage(),
          //       ),
          //     ),
          //     GoRoute(
          //       path: AppRoutes.profile,
          //       name: AppRoutes.profileName,
          //       pageBuilder: (context, state) => NoTransitionPage(
          //         key: state.pageKey,
          //         child: const ProfilePage(),
          //       ),
          //     ),
          //     GoRoute(
          //       path: AppRoutes.settings,
          //       name: AppRoutes.settingsName,
          //       pageBuilder: (context, state) => NoTransitionPage(
          //         key: state.pageKey,
          //         child: const SettingsPage(),
          //       ),
          //     ),
          //     GoRoute(
          //       path: AppRoutes.editProfile,
          //       name: AppRoutes.editProfileName,
          //       builder: (context, state) => const EditProfilePage(),
          //     ),
          //     GoRoute(
          //       path: AppRoutes.otherProfile,
          //       name: AppRoutes.otherProfileName,
          //       builder: (context, state) {
          //         final userId = state.pathParameters['userId']!;
          //         return OtherProfilePage(userId: userId);
          //       },
          //     ),
          //     GoRoute(
          //       path: AppRoutes.followingList,
          //       name: AppRoutes.followingListName,
          //       builder: (context, state) => const FollowingListPage(),
          //     ),
          //   ],
          // ),
          // GoRoute(
          //   path: AppRoutes.uploadVideo,
          //   name: AppRoutes.uploadVideoName,
          //   builder: (context, state) => const UploadVideoPage(),
          // ),
          // GoRoute(
          //   path: AppRoutes.videoPlayer,
          //   name: AppRoutes.videoPlayerName,
          //   builder: (context, state) {
          //     final videoId = state.pathParameters['videoId']!;
          //     return VideoPlayerPage(videoId: videoId);
          //   },
          // ),
          // GoRoute(
          //   path: AppRoutes.videoDetails,
          //   name: AppRoutes.videoDetailsName,
          //   builder: (context, state) {
          //     final videoId = state.pathParameters['videoId']!;
          //     return VideoDetailsPage(videoId: videoId);
          //   },
          // ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
