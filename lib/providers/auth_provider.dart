import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // Stream subscription রাখা হয়েছে যাতে dispose() এ cancel করা যায়
  StreamSubscription<User?>? _authSub;

  User? _user;
  bool _isLoading = true;
  String? _errorMessage; // UI তে error দেখানোর জন্য

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  // ─── Auth State Stream Listen ──────────────────────────────
  // Firebase login/logout হলে _user আপনাআপনি update হবে
  void _init() {
    _authSub = AuthService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // ─── Sign In ───────────────────────────────────────────────
  // error এলে _errorMessage এ রাখা হয়, UI সেটা দেখাবে
  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null; // আগের error clear করো
    notifyListeners();

    try {
      await AuthService.signIn(email: email, password: password);
      // সফল হলে authStateChanges stream _user update করবে
    } on FirebaseAuthException catch (e) {
      // error code থেকে বাংলা message বানাও
      _errorMessage = AuthService.errorMessage(e.code);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Register ─────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.register(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.errorMessage(e.code);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    await AuthService.signOut();
    // authStateChanges stream null emit করবে, _user আপনাআপনি null হবে
  }

  // ─── Error Clear ──────────────────────────────────────────
  // Login page নতুন করে খুললে আগের error সরাতে call করো
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Dispose ──────────────────────────────────────────────
  // Stream subscription cancel না করলে memory leak হয়
  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
