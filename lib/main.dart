// lib/main.dart
// এই ফাইলটি অ্যাপ্লিকেশনের এন্ট্রি পয়েন্ট বা শুরু করার জায়গা

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart' show AuthWrapper;
import 'firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/settings_provider.dart';

Future<void> _tryInitFirebase() async {
  final firebaseOptions = FirebaseService.options;

  // Production-safe: do not block UI even if Firebase config is missing.
  // If options are null/invalid, Firebase features may not work, but app must load.
  if (firebaseOptions == null) return;

  await Firebase.initializeApp(options: firebaseOptions);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _tryInitFirebase();
  } catch (e) {
    debugPrint('Firebase initialization error (non-fatal): $e');
  }

  runApp(const MyApp());
}

/// Kept for reference.
/// If you want a hard failure screen, replace `runApp(const MyApp())` above with `ConfigErrorApp`.
class ConfigErrorApp extends StatelessWidget {
  final String? message;
  const ConfigErrorApp({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Configuration Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  message ??
                      'Missing Firebase configuration.\n\n'
                          'Set these as Vercel Build-time dart-define values:\n'
                          '- FIREBASE_API_KEY\n'
                          '- FIREBASE_AUTH_DOMAIN\n'
                          '- FIREBASE_PROJECT_ID\n'
                          '- FIREBASE_STORAGE_BUCKET\n'
                          '- FIREBASE_MESSAGING_SENDER_ID\n'
                          '- FIREBASE_APP_ID\n\n'
                          'Then rebuild/redeploy.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'IALT - Inventory Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
