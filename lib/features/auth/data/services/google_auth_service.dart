import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokemon_collector/core/services/auth_service.dart';

class GoogleAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth;

  GoogleAuthService(this._firebaseAuth);

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential userCredential =
      await _firebaseAuth.signInWithProvider(googleProvider);

      return userCredential.user;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}
