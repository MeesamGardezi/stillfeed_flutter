import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/pages/forgot_password_page.dart';
import '../auth/pages/login_page.dart';
import '../auth/pages/signup_page.dart';
import '../auth/services/auth_notifier.dart';
import '../auth/models/auth_state.dart';
import '../feed/pages/feed_page.dart';
import '../home/pages/main_layout_page.dart';
import '../core/constants/colors.dart';
import 'routes.dart';

// Global auth notifier instance
final globalAuthNotifier = AuthNotifier();

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.feed,
    redirect: (context, state) async {
      final authStatus = globalAuthNotifier.value.status;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      print('Router redirect - Location: ${state.matchedLocation}, Auth Status: $authStatus');

      // If initial state, check authentication status first
      if (authStatus == AuthStatus.initial) {
        print('Router: Initial state, checking auth...');
        await globalAuthNotifier.checkAuthStatus();
        final newStatus = globalAuthNotifier.value.status;
        print('Router: Auth check complete, new status: $newStatus');
        
        // After checking, redirect based on new status
        if (newStatus == AuthStatus.authenticated && isAuthRoute) {
          return AppRoutes.feed;
        } else if (newStatus == AuthStatus.unauthenticated && !isAuthRoute) {
          return AppRoutes.login;
        } else if (newStatus == AuthStatus.error && !isAuthRoute) {
          return AppRoutes.login;
        }
        return null;
      }

      // If loading, show splash screen
      if (authStatus == AuthStatus.loading) {
        print('Router: Loading state');
        return '/splash';
      }

      // If error, redirect to login
      if (authStatus == AuthStatus.error && !isAuthRoute) {
        print('Router: Error state, redirecting to login');
        return AppRoutes.login;
      }

      // If not authenticated, redirect to login (except for auth routes)
      if (authStatus == AuthStatus.unauthenticated && !isAuthRoute) {
        print('Router: Not authenticated, redirecting to login');
        return AppRoutes.login;
      }

      // If authenticated, redirect away from auth routes
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