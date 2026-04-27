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


CODE AUDIT REPORT
IALT — Inventory & Logistics Tracking System
Repository: github.com/MdEnamulHaque007/ialt
Audit Date: April 27, 2026


Executive Summary
IALT is a Flutter/Firebase web application for inventory management in the footwear/manufacturing sector. The codebase is approximately 20,000 lines of Dart across 30+ source files. The overall quality is intermediate — the architecture and state management are solid, but there are critical security, structural, and maintainability issues that should be addressed before production hardening.

Attribute
Detail
Project Name
IALT — Inventory & Logistics Tracking
Framework
Flutter (Dart) — Web + Android + iOS
Backend
Firebase Firestore + Firebase Auth
Deployment
Vercel (Web)
Total Lines of Code
~20,180 lines across 30+ Dart files
Critical Issues Found
3 Critical, 4 High, 5 Medium, 3 Low
Overall Risk Level
HIGH — Requires fixes before production scale



1. Security Findings
🔴 CRITICAL — Security
Issues that expose data or enable unauthorized access


CRITICAL
Firebase credentials loaded from .env bundled as a Flutter asset
In pubspec.yaml, the .env file is declared as a Flutter asset (assets: - .env). Flutter bundles all assets into the final web build, making the .env file — including Firebase API keys, project IDs, and sender IDs — publicly downloadable from the deployed Vercel app at /assets/.env.
→ Remove .env from the Flutter assets list. For web, inject env vars at build time via Vercel environment variables and use dart-define or a server-side proxy. Rotate all Firebase credentials immediately.


CRITICAL
No Firestore Security Rules in repository
There are no firestore.rules or firebase.json files committed to the repository. Without rules, Firestore defaults to test mode which allows any authenticated (or even unauthenticated, depending on setup) user to read/write any collection. All business data — purchase orders, production records, export data — is potentially exposed.
→ Define and deploy Firestore Security Rules. At minimum: require auth.uid != null for all reads/writes. Ideally scope rules per collection based on user roles.


CRITICAL
.gitignore has a merge conflict / binary corruption
The .gitignore file contains unresolved Git merge conflict markers (<<<, ===, >>>) and binary null bytes. This means the file is not being correctly parsed by Git. As a result .env, pubspec_new.yaml, and other sensitive exclusions may not actually be gitignored.
→ Resolve the merge conflict manually, remove binary characters, and verify the file is ASCII-clean. Then run git status to confirm .env is untracked.


2. Architecture & Code Structure
🟠 HIGH — Architecture
Structural issues that increase maintenance cost and bug risk


HIGH
Massive duplicate files between lib/ root and lib/pages/
Every major page (issue.dart, export.dart, login_page.dart, master_lc_page.dart, production_page.dart, purchase_order_page.dart) exists TWICE — once in lib/ root and once in lib/pages/. Each file is 1,200–2,400 lines. This creates ~10,000 lines of potentially divergent duplicate code with no clear source of truth.
→ Delete the root-level duplicates and ensure all imports reference the lib/pages/ versions. Audit for any divergence between copies before deleting.


HIGH
Inconsistent Firestore collection names across the codebase
Collection names are used inconsistently: 'Purchase Order' vs 'purchase_order', 'Production' (capital P) vs implied lowercase. This caused a documented bug in TODO-issue.md where the IssuePage dropdown failed because the wrong collection name was used. AppConstants defines the correct names but they are not used everywhere.
→ Audit all collection() calls and replace with AppConstants values: colPurchaseOrder, colProduction, colIssue. The dashboard.dart still directly hardcodes 'Production' — migrate this too.


HIGH
DataProvider does bulk-loads all data at startup with no pagination or caching strategy
DataProvider.loadAllData() fetches all documents from Purchase Order, Production, and issue collections in parallel at app start. For growing datasets this will cause slow startup, high Firestore read costs, and potential memory pressure. There is also a refresh() method that re-fetches everything from scratch.
→ Implement pagination (Firestore startAfter cursors), lazy loading per page, or at minimum a TTL-based cache. Use Firestore real-time streams only where live updates are essential.


HIGH
firebase_options.dart is deprecated but still present
The file lib/firebase_options.dart contains only the comment '// Deprecated - use lib/firebase_service.dart instead' but remains in the repo. Dead files create confusion about which implementation to trust.
→ Delete firebase_options.dart. Verify no file imports it.


3. Code Quality Issues
🟡 MEDIUM — Code Quality
Issues that affect maintainability, readability, and correctness


MEDIUM
print() used instead of debugPrint() in production services
Two production service files (activity_log_service.dart and firebase_service.dart) use print() for error logging. Unlike debugPrint(), print() is not stripped in release builds and can leak error details including Firestore paths.
→ Replace all print() calls with debugPrint(). Consider integrating a proper logging package (e.g., logger) for structured log levels.


MEDIUM
Single test covering minimal smoke test only
The project has exactly one test (widget_test.dart) which only checks that MyApp renders a MaterialApp. There are no unit tests for services, providers, or business logic. The models, FirestoreService, PurchaseOrderService, and validation logic are entirely untested.
→ Add unit tests for models (fromFirestore/toFirestore round-trips), service layer (mock Firestore), and provider state transitions. Aim for at least 50% coverage of the lib/services and lib/providers directories.


MEDIUM
Activity Log page in navigation is a placeholder stub
The ActivityLogPage in main_navigation.dart resolves to a _PlaceholderPage widget ('Activity Log page coming soon…'). There is a fully-implemented lib/pages/activity_log.dart page that is never wired up.
→ Replace the ActivityLogPage stub in main_navigation.dart with an import of lib/pages/activity_log.dart.


MEDIUM
AnimationController not disposed in some pages
PurchaseOrderPage uses an AnimationController but must be carefully audited — dispose() is called, which is correct. However, the pattern should be reviewed across all pages with similar controllers to ensure no leaks.
→ Audit all StatefulWidget pages for proper disposal of TextEditingControllers, AnimationControllers, and StreamSubscriptions. Use the Flutter DevTools memory profiler to verify.


MEDIUM
Firestore queries use direct string literals scattered across UI pages
Pages like dashboard.dart directly call FirebaseFirestore.instance.collection('master_lc') and other collections, bypassing FirestoreService. This creates tight coupling between UI and data layer.
→ Route all Firestore access through the service layer (FirestoreService or domain-specific services). UI pages should never reference FirebaseFirestore.instance directly.


4. Low-Priority Observations
🟢 LOW — Improvements
Minor issues and suggestions for polish


LOW
pubspec_new.yaml committed to repository
A file pubspec_new.yaml exists in the root. This appears to be a working copy from a dependency migration and should not be in version control.
→ Delete pubspec_new.yaml and commit the removal.


LOW
Report and About nav items are stubs
Report and About pages in the navigation drawer resolve to placeholder pages. This is fine for early development but the nav items create a false impression of features.
→ Either implement these pages or hide them from the navigation until ready.


LOW
Error messages in firebase_auth_service.dart are in Bengali only
Error messages returned by AuthService.errorMessage() are written in Bengali. While appropriate for the target users, this should be documented and considered if the app is ever internationalized.
→ Document the localization decision in a README. Consider using the intl package with proper l10n/arb files for future-proofing.



5. Summary & Remediation Priority
The table below lists all findings ranked by priority for remediation.

#
Finding
Severity
Effort
1
.env exposed as Flutter asset
CRITICAL
Low
2
No Firestore Security Rules
CRITICAL
Medium
3
.gitignore corrupted/merge conflict
CRITICAL
Low
4
Duplicate files in lib/ and lib/pages/
HIGH
Low
5
Inconsistent collection names
HIGH
Low
6
Bulk data load at startup, no pagination
HIGH
High
7
Deprecated firebase_options.dart not removed
HIGH
Low
8
print() in production services
MEDIUM
Low
9
Minimal test coverage (1 test)
MEDIUM
High
10
ActivityLogPage is a stub — not wired
MEDIUM
Low
11
UI pages bypass service layer for Firestore
MEDIUM
Medium
12
Multiple direct string collection references
MEDIUM
Medium
13
pubspec_new.yaml in version control
LOW
Low
14
Placeholder nav items (Report, About)
LOW
Low
15
Bengali-only error messages undocumented
LOW
Low


6. Positive Observations
Despite the issues above, the codebase demonstrates several good engineering practices:

Provider pattern used correctly — AuthProvider, DataProvider, and SettingsProvider are well-structured with proper ChangeNotifier disposal via StreamSubscription cancellation.
Typed Firestore models — PurchaseOrder, PurchaseOrderLine, and other model classes properly separate data mapping from business logic with fromFirestore/toFirestore.
AppConstants centralizes collection and field names — the intent is correct, though not consistently applied.
FirestoreService provides a generic, reusable data access layer — CRUD and stream operations are properly abstracted.
Firebase credentials loaded from environment variables via flutter_dotenv — the approach is correct in principle, only the asset bundling is the problem.
Authentication is well-implemented — Firebase Auth stream subscription, proper loading states, and error codes mapped to user-friendly messages.
Activity logging infrastructure exists — the activity_log_service.dart and Firestore activity_log collection are a good foundation for audit trails.

7. Immediate Action Plan
Complete these steps before any public or client-facing deployment:

Step
Action
When
1
Remove .env from Flutter assets list in pubspec.yaml and rotate all Firebase credentials
Immediately
2
Fix .gitignore merge conflict, verify .env is untracked, force push
Immediately
3
Write and deploy Firestore Security Rules requiring authentication
Before next deployment
4
Delete all root-level duplicate page files (lib/*.dart) — keep only lib/pages/
This sprint
5
Standardize all collection names via AppConstants throughout the codebase
This sprint
6
Wire ActivityLogPage to lib/pages/activity_log.dart in main_navigation.dart
This sprint
7
Replace print() with debugPrint() in all service files
This sprint
8
Delete firebase_options.dart and pubspec_new.yaml
This sprint


Audit Conclusion
The IALT codebase has a solid architectural foundation using Flutter, Firebase, and the Provider pattern. However, three critical security vulnerabilities — exposed credentials, missing Firestore rules, and a corrupted .gitignore — must be resolved before the application handles real production data. Structural cleanup (removing duplicate files, standardizing collection names) will significantly reduce future bug risk. With the remediation steps above completed, the codebase will be in a strong position for continued development.


