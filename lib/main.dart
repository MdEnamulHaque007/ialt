import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ialt/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:ialt/providers/data_provider.dart';
import 'providers/auth_provider.dart';
import 'app.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: FirebaseService.options);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
