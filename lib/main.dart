// lib/main.dart
// এই ফাইলটি অ্যাপ্লিকেশনের এন্ট্রি পয়েন্ট বা শুরু করার জায়গা

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart' show AuthWrapper;
import 'firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found. $e');
  }

  final firebaseOptions = FirebaseService.options;
  if (firebaseOptions == null) {
    runApp(const ConfigErrorApp());
    return;
  }

  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    runApp(ConfigErrorApp(message: 'Firebase initialization failed.\n\n$e'));
    return;
  }

  runApp(const MyApp());
}

/// Shown when Firebase config is missing or invalid
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
                          'Please create a .env file in the project root with:\n\n'
                          'FIREBASE_API_KEY=your_api_key\n'
                          'FIREBASE_AUTH_DOMAIN=your_auth_domain\n'
                          'FIREBASE_PROJECT_ID=your_project_id\n'
                          'FIREBASE_STORAGE_BUCKET=your_storage_bucket\n'
                          'FIREBASE_MESSAGING_SENDER_ID=your_sender_id\n'
                          'FIREBASE_APP_ID=your_app_id\n\n'
                          'Then restart the app.',
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
