import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/auth_state.dart';
import '../../core/models/user_model.dart';

class AuthNotifier extends ValueNotifier<AuthState> {
  final AuthService _authService = AuthService();
  bool _isInitializing = false;

  AuthNotifier() : super(AuthState.initial()) {
    _init();
  }

  void _init() {
    print('AuthNotifier: Initializing auth state listener');
    
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen((firebaseUser) async {
      print('AuthNotifier: Firebase auth state changed - User: ${firebaseUser?.email ?? "null"}');
      
      // Ignore if we're in the middle of an explicit auth operation
      if (_isInitializing) {
        print('AuthNotifier: Skipping - initialization in progress');
        return;
      }
      
      if (firebaseUser == null) {
        // User signed out
        print('AuthNotifier: User signed out');
        value = AuthState.unauthenticated();
      } else {
        // Firebase user exists but don't auto-load profile
        // Let the router handle initial auth check
        print('AuthNotifier: Firebase user exists, waiting for explicit action');
        // Stay in initial state - don't auto-authenticate
        if (value.status == AuthStatus.initial) {
          // Don't change state, let router handle it
        }
      }
    });
  }

  /// Check if user is authenticated and load profile
  /// This is called by the router on app startup
  Future<void> checkAuthStatus() async {
    if (_authService.currentUser == null) {
      print('AuthNotifier: No Firebase user, setting unauthenticated');
      value = AuthState.unauthenticated();
      return;
    }

    try {
      print('AuthNotifier: Checking auth status - loading profile...');
      value = AuthState.loading();
      
      final user = await _authService.getUserProfile();
      print('AuthNotifier: ✓ Profile loaded, user authenticated');
      value = AuthState.authenticated(user);
    } catch (e) {
      print('AuthNotifier: ✗ Failed to load profile: $e');
      // Profile fetch failed, sign out to force re-authentication
      await _authService.signOut();
      value = AuthState.unauthenticated();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String? bio,
  }) async {
    try {
      print('AuthNotifier: Starting sign up...');
      _isInitializing = true;
      value = AuthState.loading();

      // Step 1: Create Firebase auth user
      print('AuthNotifier: Step 1 - Creating Firebase user');
      await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      // Step 2: Register user profile in backend (with retry)
      print('AuthNotifier: Step 2 - Registering user profile');
      UserModel? user;
      int retries = 3;
      Exception? lastError;
      
      for (int i = 0; i < retries; i++) {
        try {
          user = await _authService.registerUserProfile(
            displayName: displayName,
            email: email,
            bio: bio,
          );
          break; // Success, exit loop
        } catch (e) {
          lastError = e as Exception;
          print('AuthNotifier: Profile registration attempt ${i + 1} failed: $e');
          if (i < retries - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          }
        }
      }

      if (user != null) {
        print('AuthNotifier: ✓ Sign up complete');
        value = AuthState.authenticated(user);
      } else {
        print('AuthNotifier: ✗ Failed to register profile after $retries attempts');
        throw lastError ?? Exception('Failed to register user profile');
      }
    } catch (e) {
      print('AuthNotifier: ✗ Sign up error: $e');
      value = AuthState.error(e.toString());
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthNotifier: Starting sign in...');
      _isInitializing = true;
      value = AuthState.loading();

      // Step 1: Sign in with Firebase
      print('AuthNotifier: Step 1 - Signing in with Firebase');
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      // Step 2: Get user profile from backend (with retry)
      print('AuthNotifier: Step 2 - Fetching user profile');
      UserModel? user;
      int retries = 3;
      Exception? lastError;
      
      for (int i = 0; i < retries; i++) {
        try {
          user = await _authService.getUserProfile();
          break; // Success, exit loop
        } catch (e) {
          lastError = e as Exception;
          print('AuthNotifier: Profile fetch attempt ${i + 1} failed: $e');
          if (i < retries - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          }
        }
      }
      
      if (user != null) {
        print('AuthNotifier: ✓ Sign in complete');
        value = AuthState.authenticated(user);
      } else {
        print('AuthNotifier: ✗ Failed to fetch profile after $retries attempts');
        // Firebase auth succeeded but profile fetch failed
        throw lastError ?? Exception('Unable to load profile. Please check your connection.');
      }
    } catch (e) {
      print('AuthNotifier: ✗ Sign in error: $e');
      value = AuthState.error(e.toString());
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? profilePicUrl,
  }) async {
    try {
      print('AuthNotifier: Updating profile...');
      final updatedUser = await _authService.updateProfile(
        displayName: displayName,
        bio: bio,
        profilePicUrl: profilePicUrl,
      );
      print('AuthNotifier: ✓ Profile updated');
      value = AuthState.authenticated(updatedUser);
    } catch (e) {
      print('AuthNotifier: ✗ Update profile error: $e');
      value = AuthState.error(e.toString());
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      print('AuthNotifier: Sending password reset to $email');
      await _authService.sendPasswordResetEmail(email);
      print('AuthNotifier: ✓ Password reset sent');
    } catch (e) {
      print('AuthNotifier: ✗ Password reset error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      print('AuthNotifier: Signing out...');
      await _authService.signOut();
      value = AuthState.unauthenticated();
      print('AuthNotifier: ✓ Signed out');
    } catch (e) {
      print('AuthNotifier: ✗ Sign out error: $e');
      value = AuthState.error(e.toString());
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      print('AuthNotifier: Deleting account...');
      value = AuthState.loading();
      await _authService.deleteAccount();
      value = AuthState.unauthenticated();
      print('AuthNotifier: ✓ Account deleted');
    } catch (e) {
      print('AuthNotifier: ✗ Delete account error: $e');
      value = AuthState.error(e.toString());
      rethrow;
    }
  }

  UserModel? get currentUser => value.user;

  bool get isAuthenticated => value.isAuthenticated;
}