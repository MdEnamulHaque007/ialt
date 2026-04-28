import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  static FirebaseOptions? _options;
  static FirebaseOptions? get options {
    if (_options == null) {
      try {
        final apiKey = dotenv.env['FIREBASE_API_KEY'];
        final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
        final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
        final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
        final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
        final appId = dotenv.env['FIREBASE_APP_ID'];

        if (apiKey == null ||
            apiKey.isEmpty ||
            projectId == null ||
            projectId.isEmpty) {
          debugPrint(
            'FirebaseService: Missing or empty FIREBASE_API_KEY / FIREBASE_PROJECT_ID in .env',
          );
          return null;
        }

        _options = FirebaseOptions(
          apiKey: apiKey,
          authDomain: authDomain ?? '',
          projectId: projectId,
          storageBucket: storageBucket ?? '',
          messagingSenderId: messagingSenderId ?? '',
          appId: appId ?? '',
        );
      } catch (e) {
        debugPrint('FirebaseService: Error loading options from .env: $e');
        return null;
      }
    }
    return _options;
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
