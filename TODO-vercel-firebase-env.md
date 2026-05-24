# TODO-vercel-firebase-env

## Goal
Fix runtime error:
`FirebaseService: Missing FIREBASE_API_KEY or FIREBASE_PROJECT_ID. Set them via Vercel build-time --dart-define.`

## What’s wrong
- `lib/firebase_service.dart` uses `String.fromEnvironment('FIREBASE_API_KEY')` and `String.fromEnvironment('FIREBASE_PROJECT_ID')`.
- These values are compile-time only for Flutter Web.
- When Vercel builds without passing `--dart-define`, FirebaseOptions becomes `null`.

## Required build-time defines
At minimum:
- `--dart-define=FIREBASE_API_KEY=...`
- `--dart-define=FIREBASE_PROJECT_ID=...`

Also recommended:
- `--dart-define=FIREBASE_AUTH_DOMAIN=...`
- `--dart-define=FIREBASE_STORAGE_BUCKET=...`
- `--dart-define=FIREBASE_MESSAGING_SENDER_ID=...`
- `--dart-define=FIREBASE_APP_ID=...`

## Step plan
1. Add Firebase values to Vercel Project Settings as Environment Variables.
   - Ensure these variables exist at **Build-time**.
2. Update Vercel build command to inject them:
   - `flutter build web --release \
      --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
      --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN \
      --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
      --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
      --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
      --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID`
3. Deploy again.
4. Verify:
   - ConfigErrorApp no longer appears.
   - Firestore operations work.

## Notes
- `vercel.json` currently only contains rewrites for SPA routing.
- You may implement the build command either in:
  - `vercel.json` (recommended for consistency), or
  - Vercel dashboard → Project Settings → Build & Output Settings → Build Command.

