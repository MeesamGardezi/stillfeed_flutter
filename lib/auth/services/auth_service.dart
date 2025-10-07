import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio;

  AuthService() : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    // Add interceptor to automatically inject auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              print('✓ Token added to request: ${options.path}');
            } else {
              print('⚠ No token available for: ${options.path}');
            }
          } catch (e) {
            print('✗ Error getting token in interceptor: $e');
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('✗ Dio error: ${error.type}, ${error.message}');
          if (error.response != null) {
            print('  Status: ${error.response?.statusCode}');
            print('  Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get ID token with retry logic
  Future<String?> _getIdToken({int maxRetries = 3}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      print('⚠ No current user for token fetch');
      return null;
    }

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Force refresh on first attempt after sign-in to ensure fresh token
        final token = await user.getIdToken(attempt == 0);
        if (token != null && token.isNotEmpty) {
          print('✓ Token fetched successfully on attempt ${attempt + 1}');
          return token;
        }
      } catch (e) {
        print('✗ Token fetch attempt ${attempt + 1} failed: $e');
        if (attempt < maxRetries - 1) {
          // Wait before retrying: 100ms, 300ms, 500ms
          final delay = 100 + (attempt * 200);
          print('  Retrying in ${delay}ms...');
          await Future.delayed(Duration(milliseconds: delay));
        }
      }
    }
    
    throw AuthException('Failed to retrieve authentication token after $maxRetries attempts');
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting sign up for: $email');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✓ Firebase user created, waiting for initialization...');
      // Wait a moment for Firebase to fully initialize the user
      await Future.delayed(const Duration(milliseconds: 300));
      print('✓ Sign up complete');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('✗ Firebase auth error: ${e.code}');
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e) {
      print('✗ Sign up error: $e');
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  Future<UserModel> registerUserProfile({
    required String displayName,
    required String email,
    String? bio,
  }) async {
    try {
      print('Registering user profile...');
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'displayName': displayName,
          'email': email,
          'bio': bio,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✓ User profile registered');
        return UserModel.fromJson(response.data['data']);
      } else {
        print('✗ Unexpected status code: ${response.statusCode}');
        throw ServerException('Failed to register user profile');
      }
    } on DioException catch (e) {
      print('✗ Registration DioException: ${e.type}');
      throw _handleDioError(e);
    } catch (e) {
      print('✗ Registration error: $e');
      throw ServerException('Registration failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting sign in for: $email');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✓ Firebase sign in successful, waiting for initialization...');
      // Wait a moment for Firebase to fully initialize the session
      await Future.delayed(const Duration(milliseconds: 300));
      print('✓ Sign in complete');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('✗ Firebase auth error: ${e.code}');
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e) {
      print('✗ Sign in error: $e');
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  Future<UserModel> getUserProfile() async {
    try {
      print('Fetching user profile...');
      final response = await _dio.get(ApiConfig.profile);

      if (response.statusCode == 200) {
        print('✓ User profile fetched');
        return UserModel.fromJson(response.data['data']);
      } else {
        print('✗ Unexpected status code: ${response.statusCode}');
        throw ServerException('Failed to fetch user profile');
      }
    } on DioException catch (e) {
      print('✗ Get profile DioException: ${e.type}');
      throw _handleDioError(e);
    } catch (e) {
      print('✗ Get profile error: $e');
      throw ServerException('Failed to get profile: ${e.toString()}');
    }
  }

  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? profilePicUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (profilePicUrl != null) data['profilePicUrl'] = profilePicUrl;

      final response = await _dio.put(
        ApiConfig.profile,
        data: data,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw ServerException('Failed to update profile');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Update failed: ${e.toString()}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to send reset email: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete(ApiConfig.deleteAccount);
      await _firebaseAuth.currentUser?.delete();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Delete account failed: ${e.toString()}');
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  Exception _handleDioError(DioException e) {
    // Log for debugging
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('DioException Details:');
    print('  Type: ${e.type}');
    print('  Message: ${e.message}');
    print('  Response status: ${e.response?.statusCode}');
    print('  Response data: ${e.response?.data}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      // Try to extract message from response
      String message = 'Request failed';
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error']?['message'] ?? message;
      }
      
      if (statusCode == 401) {
        return AuthException(message);
      } else if (statusCode == 400) {
        return ValidationException(message);
      } else if (statusCode == 404) {
        return NotFoundException(message);
      } else {
        return ServerException(message);
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException('Connection timeout. Please check your internet connection and try again.');
    } else if (e.type == DioExceptionType.connectionError) {
      return NetworkException('Unable to connect to server. Please check your internet connection.');
    } else if (e.type == DioExceptionType.badCertificate) {
      return NetworkException('Security certificate error. Please check your connection.');
    } else if (e.type == DioExceptionType.cancel) {
      return NetworkException('Request was cancelled');
    } else {
      return NetworkException('Network error: ${e.message ?? "Please check your internet connection"}');
    }
  }
}