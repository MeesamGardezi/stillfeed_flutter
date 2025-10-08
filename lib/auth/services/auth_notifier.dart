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
      
      // Don't auto-update state during manual operations
      if (_isInitializing) {
        print('AuthNotifier: Skipping auto-update during manual operation');
        return;
      }
      
      // Only auto-update to unauthenticated when user signs out
      if (firebaseUser == null && value.status != AuthStatus.initial) {
        print('AuthNotifier: User signed out');
        value = AuthState.unauthenticated();
      }
    });
  }

  /// Check if user is authenticated and load profile
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

      // Step 2: Register user profile in backend
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
          break; // Success
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
        // Clean up Firebase user if backend registration fails
        await _authService.signOut();
        throw lastError ?? Exception('Failed to complete registration. Please try again.');
      }
    } catch (e) {
      print('AuthNotifier: ✗ Sign up error: $e');
      // Set error state with user-friendly message
      String errorMessage = _getErrorMessage(e);
      value = AuthState.error(errorMessage);
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

      // Step 2: Get user profile from backend
      print('AuthNotifier: Step 2 - Fetching user profile');
      UserModel? user;
      int retries = 3;
      Exception? lastError;
      
      for (int i = 0; i < retries; i++) {
        try {
          user = await _authService.getUserProfile();
          break; // Success
        } catch (e) {
          lastError = e as Exception;
          print('AuthNotifier: Profile fetch attempt ${i + 1} failed: $e');
          
          // Check if this is a "profile not found" error
          if (e.toString().contains('not found')) {
            print('AuthNotifier: User exists in Firebase but not in backend');
            // This user exists in Firebase but not in backend
            // Could happen if registration failed previously
            break;
          }
          
          if (i < retries - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          }
        }
      }
      
      if (user != null) {
        print('AuthNotifier: ✓ Sign in complete');
        value = AuthState.authenticated(user);
      } else {
        print('AuthNotifier: ✗ Profile not found or failed to load');
        // Sign out from Firebase since backend profile doesn't exist
        await _authService.signOut();
        throw Exception('Account setup incomplete. Please contact support or create a new account.');
      }
    } catch (e) {
      print('AuthNotifier: ✗ Sign in error: $e');
      // Set error state with user-friendly message
      String errorMessage = _getErrorMessage(e);
      value = AuthState.error(errorMessage);
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
      String errorMessage = _getErrorMessage(e);
      value = AuthState.error(errorMessage);
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
      _isInitializing = true;
      await _authService.signOut();
      value = AuthState.unauthenticated();
      print('AuthNotifier: ✓ Signed out');
    } catch (e) {
      print('AuthNotifier: ✗ Sign out error: $e');
      String errorMessage = _getErrorMessage(e);
      value = AuthState.error(errorMessage);
      rethrow;
    } finally {
      _isInitializing = false;
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
      String errorMessage = _getErrorMessage(e);
      value = AuthState.error(errorMessage);
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    if (value.status == AuthStatus.error) {
      value = AuthState.unauthenticated();
    }
  }

  /// Convert exceptions to user-friendly messages
  String _getErrorMessage(dynamic error) {
    String errorString = error.toString();
    
    if (errorString.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in instead.';
    } else if (errorString.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email address. Please check and try again.';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('not found')) {
      return 'Account not found. Please check your credentials.';
    } else if (errorString.contains('incomplete')) {
      return errorString.replaceAll('Exception: ', '');
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  UserModel? get currentUser => value.user;
  bool get isAuthenticated => value.isAuthenticated;
}