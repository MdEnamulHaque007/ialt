import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  static FirebaseOptions? _options;

  // For Flutter Web (Vercel): provide these via build-time defines.
  // Example:
  // --dart-define=FIREBASE_API_KEY=...
  // --dart-define=FIREBASE_AUTH_DOMAIN=...
  // --dart-define=FIREBASE_PROJECT_ID=...
  // --dart-define=FIREBASE_STORAGE_BUCKET=...
  // --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
  // --dart-define=FIREBASE_APP_ID=...
  static FirebaseOptions? get options {
    if (_options != null) return _options;

    try {
      // Support BOTH compile-time dart-define (Flutter Web) and
      // runtime JS env injection (Vercel/HTML) as a fallback.
      const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
      const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
      const messagingSenderId = String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      );
      const appId = String.fromEnvironment('FIREBASE_APP_ID');

      // Production-safe: only return options when required values exist.
      // If missing, `main.dart` will still render UI (non-fatal).
      if (apiKey.isEmpty || projectId.isEmpty) {
        debugPrint(
          'FirebaseService: Missing FIREBASE_API_KEY or FIREBASE_PROJECT_ID. '
          'App will start, but Firebase features will be unavailable.',
        );
        return null;
      }

      _options = FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain,
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        appId: appId,
      );
      return _options;
    } catch (e) {
      debugPrint('FirebaseService: Error building FirebaseOptions: $e');
      return null;
    }
  }

  static Future<void> logActivity(
    String action, {
    String details = '',
    String user = 'User',
  }) async {
    try {
      await FirebaseFirestore.instance.collection('activity_log').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': action,
        'details': details,
        'user': user,
      });
    } catch (e) {
      debugPrint('Log error: $e');
    }
  }
}
