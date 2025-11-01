import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential = await _auth.signInWithProvider(googleProvider);
      
      return userCredential.user;
    } catch (e) {
      debugPrint('Ошибка при входе через Google: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Ошибка при выходе: $e');
      rethrow;
    }
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  static User? get currentUser => _auth.currentUser;
}