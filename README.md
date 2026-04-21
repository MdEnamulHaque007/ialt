# IALT - Inventory Management System

A Flutter-based management application for footwear/manufacturing businesses.
Live at: https://ialt.vercel.app

## Features
- Purchase Order management with Master LC tag integration
- Production tracking
- Issue tracking
- Stock management
- Dashboard with analytics
- Activity logging

## Tech Stack
- Flutter (Dart)
- Firebase Firestore
- Firebase Authentication
- Vercel (Web deployment)

## Setup

### Prerequisites
- Flutter SDK
- Firebase project
- Node.js (for Vercel CLI)

### Installation
1. Clone the repo:
   git clone https://github.com/MdEnamulHaque007/ialt.git
   cd ialt

2. Install dependencies:
   flutter pub get

3. Setup environment:
   cp .env.example .env
   (Fill in your Firebase credentials in .env)

4. Run the app:
   flutter run -d chrome

## Environment Variables
See .env.example for required variables.
Never commit your .env file.

## Deployment
vercel --prod
