import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late StreamSubscription<User?> _authSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _user = _authService.currentUser;
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get displayName {
    if (_user?.displayName != null && _user!.displayName!.trim().isNotEmpty) {
      return _user!.displayName!;
    }
    if (_user?.email != null) {
      return _user!.email!.split('@').first;
    }
    return 'Cashier Member';
  }

  String get email => _user?.email ?? '';
  String? get photoUrl => _user?.photoURL;
  bool get isGoogleUser => _authService.isGoogleUser;
  bool get isPasswordLinked => _authService.isPasswordLinked;
  List<String> get linkedProviders => _authService.linkedProviders;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign In with Email & Password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signInWithEmail(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Sign Up with Email & Password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Sign In with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final cred = await _authService.signInWithGoogle();
      _setLoading(false);
      if (cred != null) {
        return true;
      } else {
        // User cancelled
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Send Password Reset
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Link Email & Password to current logged-in user (e.g. Google user)
  Future<bool> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.linkEmailPassword(email: email, password: password);
      _user = _authService.currentUser;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Update password for account
  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.updatePassword(newPassword);
      _user = _authService.currentUser;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _setLoading(false);
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
