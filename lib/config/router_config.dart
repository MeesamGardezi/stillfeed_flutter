import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/pages/forgot_password_page.dart';
import '../auth/pages/login_page.dart';
import '../auth/pages/signup_page.dart';
import '../auth/services/auth_notifier.dart';
import '../auth/models/auth_state.dart';
import '../feed/pages/feed_page.dart';
import '../feed/pages/upload_video_page.dart';
import '../feed/pages/video_player_page.dart';
import '../home/pages/main_layout_page.dart';
import '../core/constants/colors.dart';
import '../core/models/video_model.dart';
import 'routes.dart';

// Global auth notifier instance
final globalAuthNotifier = AuthNotifier();

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.feed,
    redirect: (context, state) async {
      final authState = globalAuthNotifier.value;
      final authStatus = authState.status;
      final location = state.matchedLocation;
      
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.forgotPassword;
      
      final isSplash = location == '/splash';

      print('Router redirect - Location: $location, Auth Status: $authStatus');

      // Initial app load - check auth status
      if (authStatus == AuthStatus.initial) {
        print('Router: Initial state, checking auth...');
        // Show splash while checking
        if (!isSplash) {
          return '/splash';
        }
        // Start auth check
        globalAuthNotifier.checkAuthStatus().then((_) {
          // Auth check complete, router will redirect again
        });
        return null; // Stay on splash
      }

      // If we're on splash and auth is determined, redirect appropriately
      if (isSplash) {
        if (authStatus == AuthStatus.authenticated) {
          print('Router: Leaving splash, authenticated');
          return AppRoutes.feed;
        } else if (authStatus == AuthStatus.unauthenticated || 
                   authStatus == AuthStatus.error) {
          print('Router: Leaving splash, not authenticated');
          return AppRoutes.login;
        }
        // Still loading, stay on splash
        return null;
      }

      // Don't redirect during active auth operations on auth pages
      if (authStatus == AuthStatus.loading && isAuthRoute) {
        print('Router: Loading state on auth page, no redirect');
        return null;
      }

      // Stay on auth page to show errors
      if (authStatus == AuthStatus.error && isAuthRoute) {
        print('Router: Error state on auth page, staying to show error');
        return null;
      }

      // Redirect to login on error for protected pages
      if (authStatus == AuthStatus.error && !isAuthRoute) {
        print('Router: Error state on protected page, redirecting to login');
        return AppRoutes.login;
      }

      // Redirect unauthenticated users to login
      if (authStatus == AuthStatus.unauthenticated && !isAuthRoute) {
        print('Router: Not authenticated, redirecting to login');
        return AppRoutes.login;
      }

      // Redirect authenticated users away from auth pages
      if (authStatus == AuthStatus.authenticated && isAuthRoute) {
        print('Router: Already authenticated, redirecting to feed');
        return AppRoutes.feed;
      }

      print('Router: No redirect needed');
      return null;
    },
    refreshListenable: globalAuthNotifier,
    routes: [
      // Splash screen route
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth routes
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
      // Upload route - OUTSIDE ShellRoute so it can be pushed as modal
      GoRoute(
        path: AppRoutes.uploadVideo,
        name: AppRoutes.uploadVideoName,
        builder: (context, state) => const UploadVideoPage(),
      ),
      // Video Player route - FIXED - No path parameter, just uses extra
      GoRoute(
        path: '/video-player',
        name: AppRoutes.videoPlayerName,
        builder: (context, state) {
          final video = state.extra as Video?;
          if (video == null) {
            // If no video provided, show error
            return Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(AppRoutes.feed),
                ),
              ),
              body: const Center(
                child: Text('No video selected'),
              ),
            );
          }
          return VideoPlayerPage(video: video);
        },
      ),
      // Protected routes with shell
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
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}

// Splash screen widget
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nature_people,
              size: 64,
              color: AppColors.accentGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'StillFeed',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}