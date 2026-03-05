import '../../data/models/user_model.dart';
import '../../data/firebase/auth/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> registerStudent(String name, String email, String password, String collegeId);
  Future<void> logout();
  Stream<User?> get authStateChanges;
  User? getCurrentUser();
  Future<UserModel?> getCurrentUserModel();
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<UserModel?> login(String email, String password) {
    return _authService.loginWithEmailPassword(email, password);
  }

  @override
  Future<UserModel?> registerStudent(String name, String email, String password, String collegeId) {
    return _authService.registerStudent(name, email, password, collegeId);
  }

  @override
  Future<void> logout() {
    return _authService.signOut();
  }

  @override
  Stream<User?> get authStateChanges => _authService.authStateChanges;
  
  @override
  User? getCurrentUser() => _authService.getCurrentUser();
  
  @override
  Future<UserModel?> getCurrentUserModel() => _authService.getCurrentUserModel();
}
