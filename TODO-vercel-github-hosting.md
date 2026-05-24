# TODO: Vercel + GitHub ফ্রি হোস্টিং (IALT)

## Step 1 — Firebase .env হ্যান্ডলিং (সবচেয়ে গুরুত্বপূর্ণ)
- [ ] `pubspec.yaml` থেকে `flutter: assets: - .env` remove করা
- [ ] `.env` থেকে পড়া লজিক (flutter_dotenv) বাদ দিয়ে Vercel environment variables ব্যবহার করা
- [ ] `lib/firebase_service.dart` আপডেট করে `dotenv.env` এর বদলে `String.fromEnvironment` বা সরাসরি `const` মান ব্যবহার করা
- [ ] `lib/main.dart` থেকে `dotenv.load(...)` remove করা

## Step 2 — Flutter Web Build + Routing
- [ ] `flutter build web --release` চালিয়ে `build/web` কনফিগ ঠিক করা
- [ ] `vercel.json` verify করে routing/rewrites ঠিক আছে কিনা দেখা

## Step 3 — GitHub + Vercel ডিপ্লয় পাইপলাইন
- [ ] GitHub এ কোড push
- [ ] Vercel এ "Import Project" > GitHub থেকে সিলেক্ট
- [ ] Vercel Project Settings এ (Build-time) env vars সেট করুন/নিন
- [ ] Vercel Build Command এমন দিন যাতে dart-define inject হয়:
  - `flutter build web --release \
    --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
    --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN \
    --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
    --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
    --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID`


## Step 4 — Testing
- [ ] Vercel Preview URL এ গিয়ে login কাজ করছে কিনা দেখা
- [ ] Firestore write/read (যেমন dashboard data বা auth-protected pages) যাচাই

## Step 5 — Security
- [ ] Firestore Security Rules নিশ্চিত করা (request.auth != null)
- [ ] কোন credential যেন কমিট/পাবলিক assets এ না যায়

