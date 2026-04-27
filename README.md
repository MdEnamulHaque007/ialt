IALT - Inventory Management System

A Flutter-based Inventory & Logistics Tracking System for footwear and manufacturing businesses.

🌐 Live Demo: https://ialt.vercel.app

---

📌 Overview

IALT (Inventory & Logistics Tracking System) is designed to manage and monitor the complete workflow of footwear/manufacturing operations including Purchase Orders, Production, Issue Tracking, Stock Management, Dashboard Analytics, and Activity Logs.

This system helps improve operational efficiency, reduce manual errors, and provide real-time business insights.

---

✨ Features

📦 Purchase Order Management

- Create, update, and manage Purchase Orders
- Master LC Tag integration
- PO-based Article and Color tracking

🏭 Production Tracking

- Daily production entry and monitoring
- Factory-wise production management
- Pending vs completed production tracking

⚠️ Issue Tracking

- Production issue logging
- Issue type categorization
- Issue status monitoring

📊 Stock Management

- Raw material and finished goods tracking
- Stock In / Stock Out management
- Inventory balance calculation

📈 Dashboard & Analytics

- Real-time summary dashboard
- Business performance analytics
- Production and inventory insights

📝 Activity Logging

- User activity tracking
- Audit trail management
- System change monitoring

---

🛠 Tech Stack

Frontend

- Flutter (Dart)

Backend

- Firebase Firestore
- Firebase Authentication

Deployment

- Vercel (Web Hosting)

State Management

- Provider

---

📂 Project Structure

lib/
├── models/
├── providers/
├── services/
├── pages/
├── widgets/
├── utils/
├── constants/
└── main.dart

---

⚙️ Prerequisites

Before running this project, make sure you have installed:

- Flutter SDK
- Dart SDK
- Firebase Project Setup
- Node.js (for Vercel deployment)
- Git

---

🚀 Installation

Step 1: Clone Repository

git clone https://github.com/MdEnamulHaque007/ialt.git
cd ialt

---

Step 2: Install Dependencies

flutter pub get

---

Step 3: Setup Environment Variables

Copy the example environment file:

cp .env.example .env

Then update the ".env" file with your Firebase credentials.

Example:

FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_AUTH_DOMAIN=
FIREBASE_STORAGE_BUCKET=

⚠️ Important:

Never commit your ".env" file to GitHub.

---

Step 4: Run the Project

For web:

flutter run -d chrome

For Android:

flutter run

---

🔐 Firebase Setup

Make sure your Firebase project includes:

- Firestore Database
- Firebase Authentication
- Proper Firestore Security Rules

Recommended minimum rule:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}

---

🚀 Deployment

Deploy to Vercel:

vercel --prod

Before deployment:

- Remove ".env" from Flutter assets
- Verify ".gitignore"
- Deploy Firestore Rules
- Rotate sensitive credentials if exposed

---

📋 Important Notes

Security Recommendations

DO:

- Use Firestore Security Rules
- Use AppConstants for collection names
- Keep environment variables secure
- Route Firestore access through service layer

DON'T:

- Commit ".env"
- Hardcode Firebase credentials
- Use direct Firestore collection strings in UI pages
- Keep duplicate source files

---

🧪 Testing

Current test coverage is minimal.

Recommended improvements:

- Unit tests for Models
- Service layer tests
- Provider state transition tests
- Firestore mock testing

Run tests:

flutter test

---

📈 Future Improvements

- Pagination for Firestore queries
- Advanced reporting system
- Export module enhancement
- Better dashboard analytics
- Role-based access control
- Localization support
- Mobile optimization

---

👨‍💻 Developer

Developed by

Md Enamul Haque

Focused on scalable ERP solutions for footwear and manufacturing businesses.

---

📄 License

Private Business Application

Internal Business Use Recommended

---

⭐ Final Thoughts

IALT is not just an inventory app.

It is a scalable ERP foundation designed for real-world manufacturing operations with future expansion potential across procurement, logistics, finance, and reporting systems.