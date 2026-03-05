import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/firebase/auth/firebase_auth_service.dart';
import '../../data/models/user_model.dart';
import '../repositories/auth_repository.dart';

// Provides the FirebaseAuthService instance
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Provides the AuthRepository implementation
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthRepositoryImpl(authService);
});

// Stream of Firebase Auth changes (login/logout)
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Provides the current UserModel fetched from Firestore
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getCurrentUserModel();
});
