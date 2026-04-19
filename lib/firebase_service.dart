import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  static FirebaseOptions? _options;
  static FirebaseOptions get options {
    if (_options == null) {
      final apiKey = dotenv.env['FIREBASE_API_KEY'];
      final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
      final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
      final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
      final appId = dotenv.env['FIREBASE_APP_ID'];

      if (apiKey == null || projectId == null) {
        throw Exception('Missing Firebase env vars in .env');
      }

      _options = FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain ?? '',
        projectId: projectId,
        storageBucket: storageBucket ?? '',
        messagingSenderId: messagingSenderId ?? '',
        appId: appId ?? '',
      );
    }
    return _options!;
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
      print('Log error: $e');
    }
  }
}
