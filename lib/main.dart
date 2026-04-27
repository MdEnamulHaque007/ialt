// lib/main.dart
// এই ফাইলটি অ্যাপ্লিকেশনের এন্ট্রি পয়েন্ট বা শুরু করার জায়গা

import 'package:flutter/material.dart';
// provider প্যাকেজ থেকে ChangeNotifierProvider ইমপোর্ট করা হচ্ছে
// এটি স্টেট ম্যানেজমেন্টের জন্য ব্যবহার করা হবে
import 'package:provider/provider.dart';

// আমাদের অ্যাপের বিভিন্ন প্রোভাইডার (যারা ডাটা ম্যানেজ করে) ইমপোর্ট করা হচ্ছে
import 'providers/auth_provider.dart';
import 'providers/purchase_order_provider.dart';
import 'providers/production_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/issue_provider.dart';
import 'providers/activity_log_provider.dart';

// অথেনটিকেশন পেজ ইমপোর্ট করা হচ্ছে (যেখানে ইউজার লগইন করবে)
import 'pages/auth_page.dart';

// main() ফাংশন - যেখান থেকে পুরো অ্যাপ শুরু হয়
void main() {
  // runApp() ফাংশনটি widgets ট্রি শুরু করে
  // MyApp ক্লাসের একটি instance তৈরি করে দেখায়
  runApp(MyApp());
}

// MyApp ক্লাস - এটি পুরো অ্যাপ্লিকেশনের মূল widget
// StatelessWidget মানে এটি একবার তৈরি হলে বাইরে থেকে পরিবর্তন করা যায় না
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MultiProvider ব্যবহার করা হচ্ছে একসাথে একাধিক প্রোভাইডার যোগ করার জন্য
    // এগুলো অ্যাপের যেকোনো জায়গা থেকে ডাটা অ্যাক্সেস করতে দেয়
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider প্রতিটি প্রোভাইডারের জন্য আলাদা line এ লেখা হয়
        // প্রতিটি প্রোভাইডার একটি নির্দিষ্ট ফিচারের ডাটা এবং লজিক ম্যানেজ করে
        
        // AuthProvider: লগইন, রেজিস্ট্রেশন, লগআউট ইত্যাদি পরিচালনা করে
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // PurchaseOrderProvider: পারচেস অর্ডার সংক্রান্ত কাজ (তৈরি, আপডেট, ডিলিট)
        ChangeNotifierProvider(create: (_) => PurchaseOrderProvider()),
        
        // ProductionProvider: প্রোডাকশন বা উৎপাদন সংক্রান্ত কাজ
        ChangeNotifierProvider(create: (_) => ProductionProvider()),
        
        // StockProvider: স্টক বা মজুত সংক্রান্ত কাজ
        ChangeNotifierProvider(create: (_) => StockProvider()),
        
        // IssueProvider: ইস্যু বা সমস্যা সংক্রান্ত কাজ
        ChangeNotifierProvider(create: (_) => IssueProvider()),
        
        // ActivityLogProvider: ইউজারের প্রতিটি কাজের লগ রাখে
        ChangeNotifierProvider(create: (_) => ActivityLogProvider()),
      ],
      // MaterialApp অ্যাপের মূল কাঠামো তৈরি করে
      child: MaterialApp(
        // অ্যাপের শিরোনাম
        title: 'IALT - Inventory Management',
        
        // থিম: অ্যাপের রং, ফন্ট, স্টাইল নির্ধারণ করে
        theme: ThemeData(
          primarySwatch: Colors.blue, // প্রাইমারি কালার নীল
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        
        // home: অ্যাপ খোলার সাথে কোন পেজ দেখাবে
        // AuthPage দেখাবে, কারণ ইউজার প্রথমে লগইন করবে
        home: AuthPage(),
        
        // debugShowCheckedModeBanner: false মানে উপরের ডিবাগ ব্যানার না দেখানো
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}