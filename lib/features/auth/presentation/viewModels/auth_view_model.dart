import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pokemon_collector/features/auth/data/services/google_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final GoogleAuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthViewModel(this._authService) {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });

    _currentUser = _authService.currentUser;
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        _currentUser = user;

        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.set({
          'userId': user.uid,
          'email': user.email,
          'displayName': user.displayName,
        }, SetOptions(merge: true));

        debugPrint('Successful sign in: ${user.displayName} (${user.email})');
      } else {
        _setError('Вход отменен пользователем');
      }
    } catch (e) {
      _setError('Ошибка при входе: ${e.toString()}');
      debugPrint('Authentication error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signOut();
      _currentUser = null;

      debugPrint('Successful sign out');
    } catch (e) {
      _setError('Ошибка при выходе: ${e.toString()}');
      debugPrint('Sign out error: $e');
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
