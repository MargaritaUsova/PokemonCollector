import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pokemon_collector/features/auth/data/services/google_sign_in_service.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthViewModel() {
    _initializeAuth();
  }

  void _initializeAuth() {
    GoogleSignInService.authStateChanges.listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });

    _currentUser = GoogleSignInService.currentUser;
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await GoogleSignInService.signInWithGoogle();
      
      if (user != null) {
        _currentUser = user;
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) {
          throw Exception('Пользователь не авторизован в FirebaseAuth');
        }
        final userDoc = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
        await userDoc.set({
          'userId': firebaseUser.uid,
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
        }, SetOptions(merge: true));
        debugPrint('Успешный вход: ${user.displayName} (${user.email})');
      } else {
        _setError('Вход отменен пользователем');
      }
    } catch (e) {
      _setError('Ошибка при входе: ${e.toString()}');
      debugPrint('Ошибка авторизации: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await GoogleSignInService.signOut();
      _currentUser = null;
      
      debugPrint('Успешный выход');
    } catch (e) {
      _setError('Ошибка при выходе: ${e.toString()}');
      debugPrint('Ошибка выхода: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}