import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
  ));

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String?> _getIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  Future<UserModel> registerUserProfile({
    required String displayName,
    required String email,
    String? bio,
  }) async {
    try {
      final token = await _getIdToken();
      if (token == null) throw AuthException('Not authenticated');

      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'displayName': displayName,
          'email': email,
          'bio': bio,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw ServerException('Failed to register user profile');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Registration failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  Future<UserModel> getUserProfile() async {
    try {
      final token = await _getIdToken();
      if (token == null) throw AuthException('Not authenticated');

      final response = await _dio.get(
        ApiConfig.profile,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw ServerException('Failed to fetch user profile');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Failed to get profile: ${e.toString()}');
    }
  }

  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? profilePicUrl,
  }) async {
    try {
      final token = await _getIdToken();
      if (token == null) throw AuthException('Not authenticated');

      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (profilePicUrl != null) data['profilePicUrl'] = profilePicUrl;

      final response = await _dio.put(
        ApiConfig.profile,
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
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
      final token = await _getIdToken();
      if (token == null) throw AuthException('Not authenticated');

      await _dio.delete(
        ApiConfig.deleteAccount,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data['message'] ?? 'Request failed';
      
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
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return NetworkException('No internet connection');
    } else {
      return NetworkException('Network error occurred');
    }
  }
}