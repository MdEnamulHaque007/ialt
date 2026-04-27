IALT - ইনভেন্টরি ম্যানেজমেন্ট সিস্টেম
IALT (Inventory & Logistics Tracking System) হলো footwear/manufacturing ব্যবসার জন্য তৈরি একটি Flutter-ভিত্তিক ম্যানেজমেন্ট অ্যাপ্লিকেশন।
এটি মূলত Purchase Order, Production, Issue Tracking, Stock Management এবং Dashboard Analytics সহজভাবে পরিচালনার জন্য তৈরি করা হয়েছে।
🌐 Live Demo: Vercel এ হোস্ট করা অ্যাপ
https://ialt.vercel.app⁠�
✨ প্রধান ফিচারসমূহ
📦 Purchase Order Management
Purchase Order তৈরি, আপডেট এবং ট্র্যাকিং
Master LC Tag Integration
PO ভিত্তিক Article ও Color Management
🏭 Production Tracking
দৈনিক Production Entry
Factory-wise Production Monitoring
Pending vs Completed Production Tracking
⚠️ Issue Tracking
Production Issue Logging
Issue Type অনুযায়ী Categorization
Issue Status Monitoring
📊 Stock Management
Raw Material ও Finished Goods Tracking
Stock In / Stock Out Monitoring
Inventory Balance Calculation
📈 Dashboard & Analytics
Summary Dashboard
Real-time Data Insights
Business Performance Analytics
📝 Activity Logging
User Activity Tracking
Audit Trail Management
System Change Monitoring
🛠️ ব্যবহৃত প্রযুক্তি (Tech Stack)
Frontend
Flutter (Dart)
Backend
Firebase Firestore
Firebase Authentication
Deployment
Vercel (Web Deployment)
⚙️ Setup করার পূর্বশর্ত (Prerequisites)
সিস্টেম চালানোর আগে নিচের জিনিসগুলো ইনস্টল থাকতে হবে:
Flutter SDK
Firebase Project
Node.js (Vercel CLI ব্যবহারের জন্য)
🚀 Installation Guide
Step 1: Repository Clone করুন
Bash
git clone https://github.com/MdEnamulHaque007/ialt.git
cd ialt
Step 2: Dependencies Install করুন
Bash
flutter pub get
Step 3: Environment Setup করুন
Bash
cp .env.example .env
এরপর .env ফাইলের ভিতরে আপনার Firebase Project-এর প্রয়োজনীয় Credentials যুক্ত করুন।
⚠️ গুরুত্বপূর্ণ: .env ফাইল কখনো GitHub-এ Push করবেন না।
Step 4: Application Run করুন
Bash
flutter run -d chrome
এতে Web Browser-এ অ্যাপ রান হবে।
🔐 Environment Variables
প্রয়োজনীয় সকল Environment Variable-এর তালিকা .env.example ফাইলে দেওয়া আছে।
উদাহরণ:
Firebase API Key
Project ID
App ID
Messaging Sender ID
Auth Domain
⚠️ নিরাপত্তার জন্য: .env ফাইল কখনো Repository-তে Commit করবেন না।
🚀 Deployment
Production Deployment করার জন্য:
Bash
vercel --prod
এটি Vercel-এ সরাসরি Production Build Deploy করবে।
📌 গুরুত্বপূর্ণ নিরাপত্তা নির্দেশনা
Production-এ Deploy করার আগে অবশ্যই নিচের বিষয়গুলো নিশ্চিত করুন:
✅ Firestore Security Rules যুক্ত করুন
Database কখনো Test Mode-এ রাখবেন না।
✅ .env কে Flutter Assets-এ যুক্ত করবেন না
না হলে Credentials Public হয়ে যেতে পারে।
✅ .gitignore ঠিকভাবে Configure করুন
যাতে .env, temporary files এবং sensitive files GitHub-এ Upload না হয়।
✅ Collection Names Standardize করুন
সব জায়গায় একই Firestore Collection Name ব্যবহার করুন।
📂 Project Structure (সংক্ষেপে)
Plain text
lib/
 ├── models/
 ├── providers/
 ├── services/
 ├── pages/
 ├── widgets/
 ├── utils/
 └── main.dart
💡 Developer Notes
এই Project-এ:
Provider Pattern ব্যবহৃত হয়েছে
Typed Firestore Models ব্যবহার করা হয়েছে
Reusable Firestore Service Layer তৈরি করা হয়েছে
Authentication Flow properly managed
Activity Log Infrastructure প্রস্তুত আছে
📣 গুরুত্বপূর্ণ পরামর্শ
এই Project Production Scale-এ নেওয়ার আগে:
Security Hardening
Firestore Rules
Duplicate File Cleanup
Pagination Implementation
Unit Testing Coverage
অবশ্যই সম্পন্ন করা উচিত।
👨‍💻 Developer
Developed by
Md Enamul Haque
বিশেষভাবে Footwear / Manufacturing Business-এর Inventory & Logistics Management-এর জন্য তৈরি।
📄 License
Private Business Application
Internal Use Recommended
⭐ Final Note
IALT শুধুমাত্র একটি Inventory App নয়—
এটি একটি scalable ERP foundation যা ভবিষ্যতে আরও বড় Production Management System-এ রূপ নিতে পারে।