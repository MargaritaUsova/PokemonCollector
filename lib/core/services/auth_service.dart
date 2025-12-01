import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<User?> signInWithGoogle();
  Future<void> signOut();
}
