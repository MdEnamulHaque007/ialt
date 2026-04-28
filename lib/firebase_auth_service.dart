import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign In ───────────────────────────────────────────────
  // FirebaseAuthException আলাদাভাবে ধরা হয়েছে
  // যাতে error code থেকে সঠিক message দেখানো যায়
  static Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code}');
      rethrow; // AuthProvider এ catch হবে
    }
  }

  // ─── Register ─────────────────────────────────────────────
  static Future<UserCredential?> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: ${e.code}');
      rethrow;
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Error Code থেকে বাংলা Message ───────────────────────
  // AuthProvider এ rethrow করা exception এর code এখানে
  // মানুষের ভাষায় রূপান্তর করা হয়
  static String errorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'এই email এ কোনো account নেই।';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email বা password ভুল হয়েছে।';
      case 'invalid-email':
        return 'Email address সঠিক নয়।';
      case 'email-already-in-use':
        return 'এই email আগে থেকেই registered।';
      case 'weak-password':
        return 'Password কমপক্ষে ৬ অক্ষরের হতে হবে।';
      case 'too-many-requests':
        return 'অনেকবার চেষ্টা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
      case 'network-request-failed':
        return 'Internet সংযোগ নেই।';
      default:
        return 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
  }
}
