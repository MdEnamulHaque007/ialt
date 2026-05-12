# Architecture (iALT Manufacturing ERP)

> This document is derived from the current codebase in this repository (no assumptions).

---

## 1) Folder structure (from repo)

### `lib/`
- `lib/app.dart`
  - `MyApp`, `AuthWrapper` (routing between `LoginPage` and `MainNavigation`)
- `lib/main.dart`
  - Loads `.env` via `flutter_dotenv`
  - Builds `firebaseOptions` from `FirebaseService.options`
  - Calls `Firebase.initializeApp(options: ...)`
- `lib/firebase_auth_service.dart`
  - `AuthService` (Firebase email/password sign-in/sign-out/auth state)
- `lib/firebase_service.dart`
  - `FirebaseService.options` reads Firebase config values from `.env`
  - `FirebaseService.logActivity(...)` writes to `activity_log`
- `lib/providers/`
  - `auth_provider.dart` -> `AuthProvider` (listens to auth changes)
  - `data_provider.dart` -> `DataProvider` (loads collections into in-memory lists; note: `loadAllData` loads `Purchase Order`, `Production`, `issue`)
  - `settings_provider.dart` -> `SettingsProvider` (reads `settings/company_info`)
- `lib/pages/` (UI screens)
  - `dashboard.dart`
  - `login_page.dart`
  - `master_lc_page.dart` (Master L/C CRUD UI)
  - `purchase_order_page.dart`
  - `production_page.dart`
  - `issue.dart` (FG Issues CRUD UI)
  - `export.dart`
  - `stock.dart` (Stock report)
  - `setting_page.dart`
  - plus placeholders: `activity_log.dart`, `export.dart` etc. (some are minimal placeholders)
- `lib/services/` (Firestore/data logic + business calculations)
  - `activity_log_service.dart`
  - `firestore_service.dart` (generic CRUD helpers; also convenience getters)
  - `master_lc_service.dart`
  - `purchase_order_service.dart`
  - `production_service.dart`
  - `issue_service.dart`
  - `stock_service.dart`
  - (Other services referenced in UI may exist, but current code shows the above.)
- `lib/models/` (data entities)
  - `master_lc.dart`
  - `purchase_order.dart`
  - `production.dart`
  - `issue.dart`
  - `stock_report.dart`
  - `activity_log.dart`

- `lib/widgets/`
  - `main_navigation.dart` -> side drawer + `IndexedStack` routes
  - `logout_button.dart`

---

## 2) Data layer

### Data sources used
- **Firebase Authentication**: `lib/firebase_auth_service.dart` via `firebase_auth`.
- **Firestore** (primary persistence):
  - Direct Firestore usage in several pages (e.g. `master_lc_page.dart`, `purchase_order_page.dart`, `production_page.dart`, `issue.dart`, `export.dart`, `stock.dart`).
  - Service-layer Firestore usage in:
    - `lib/services/master_lc_service.dart` (collection: `master_lc`)
    - `lib/services/production_service.dart` (collection: `Production`)
    - `lib/services/issue_service.dart` (collection: `issue`)
    - `lib/services/purchase_order_service.dart` (collection: `purchase_order`)
    - `lib/services/stock_service.dart` (reads `purchase_order`, `issue`, `export`)

### Repository pattern
- There is a light “service” layer acting like repositories:
  - `MasterLCService`, `PurchaseOrderService`, `ProductionService`, `IssueService`, `StockService`.
  - Each service wraps Firestore operations and (where present) maps Firestore docs to model objects.

### Model classes (domain vs data layer)
- Models in `lib/models/` act as the typed data structures used across UI and services.
- They are not split into `domain` vs `data` packages; all are placed under `lib/models/`.

---

## 3) Domain layer (Entity models)

> The codebase currently contains these entity classes:

### `MasterLC`
- File: `lib/models/master_lc.dart`
- Fields:
  - `id: String` (Firestore doc id, required in constructor)
  - `slNo: int`
  - `tagNo: String`
  - `project: String`
  - `applicant: String`
  - `scNo: String`
  - `lcNo: String`
  - `ttNo: String`
  - `masterLcDate: String`
  - `masterLcValue: double`
  - `masterLcQty: double`
  - `createdAt: DateTime?`

### `PurchaseOrder` + `PurchaseOrderLine`
- File: `lib/models/purchase_order.dart`

`PurchaseOrderLine` fields:
- `article: String`
- `color: String`
- `qty: int`
- `unitPrice: double`
- `totalValue: double`

`PurchaseOrder` fields:
- `id: String`
- `poNo: String`
- `poDate: String`
- `orderBy: String`
- `brand: String`
- `project: String`
- `tag: String`
- `totalQuantity: int`
- `totalValue: double`
- `lines: List<PurchaseOrderLine>`
- `createdAt: DateTime?`
- `updatedAt: DateTime?`

### `Production`
- File: `lib/models/production.dart`
- Fields:
  - `id: String`
  - `poNo: String`
  - `articleNo: String`
  - `color: String`
  - `qty: int`
  - `date: String`
  - `createdAt: DateTime?`
  - `updatedAt: DateTime?`

### `Issue`
- File: `lib/models/issue.dart`
- Fields:
  - `id: String`
  - `voucherNo: String`
  - `poNo: String`
  - `articleNo: String`
  - `color: String`
  - `quantity: int`
  - `criteria: String`
  - `date: String`
  - `createdAt: DateTime?`
  - `updatedAt: DateTime?`

### `StockReport`
- File: `lib/models/stock_report.dart`
- Fields:
  - `poNo: String`
  - `articleNo: String`
  - `color: String`
  - `opening: double`
  - `issue: double`
  - `export: double`
  - `closing: double`
- `StockReport.calculate(...)`:
  - `closing = opening + issue - export`

### `ActivityLog`
- File: `lib/models/activity_log.dart`
- Fields:
  - `id: String`
  - `action: String`
  - `details: String`
  - `user: String`
  - `module: String`
  - `slNo: String`
  - `timestamp: DateTime`

---

## 4) Presentation layer

### State management
- `provider` package (ChangeNotifier + Consumer/Selector).
- Providers in this repo:
  - `AuthProvider` (file: `lib/providers/auth_provider.dart`)
    - exposes: `user`, `isLoading`, `isAuthenticated`, `errorMessage`
  - `DataProvider` (file: `lib/providers/data_provider.dart`)
    - exposes in-memory lists: `purchaseOrders`, `productions`, `issues` and `isLoading`
    - note: in-memory collections are keyed by strings like `'Purchase Order'` (not used by most pages which directly query Firestore).
  - `SettingsProvider` (file: `lib/providers/settings_provider.dart`)
    - loads `settings/company_info`.

### Screens and their patterns
- Navigation: `lib/widgets/main_navigation.dart`
  - uses `IndexedStack` over `_pages`.
  - Side drawer items map to:
    - `Dashboard` (from `lib/pages/dashboard.dart`)
    - `Master L/C` -> `MasterLcContent` (from `lib/pages/master_lc_page.dart`)
    - `Production` -> `ProductionPage`
    - `Purchase Order` -> `PurchaseOrderPage`
    - `FG Issues` -> `IssuePage` (from `lib/pages/issue.dart`)
    - `Export` -> `ExportPage` (from `lib/pages/export.dart`)
    - `Stock` -> `StockReport` (from `lib/pages/stock.dart`)
    - `Activity Log` and others are placeholder UI.

### CRUD UI style (what exists in current code)
- **Master L/C**: full CRUD UI with add/edit/delete + search + autocomplete
  - file: `lib/pages/master_lc_page.dart`
- **Purchase Order**: create/edit/delete dialogs + line items
  - file: `lib/pages/purchase_order_page.dart`
- **Production**: add/update/delete with table and pagination
  - file: `lib/pages/production_page.dart`
- **Issue (FG Issues)**: add/update/delete with DataTable, filters, date range, pagination
  - file: `lib/pages/issue.dart`
- **Export**: add/update/delete with DataTable, filters, pagination; includes quantity remaining checks
  - file: `lib/pages/export.dart`

---

## 5) Business logic

### ERPBusinessEngine
- The provided code does **not** contain an `ERPBusinessEngine` class.
- Business validations and constraints currently live inside the UI pages and/or calculations inside `StockService`.

### Validation flow (Cutting → Sewing → Production → Issue → Export)
- The current repository includes entities + screens for:
  - `Master LC` / `Purchase Order` / `Production` / `Issue` / `Export`.
- Cutting and Sewing steps are not implemented as entities/screens in the current code.

### Validation examples that exist in code
- `IssuePage` (in `lib/pages/issue.dart`):
  - before saving issue, checks:
    - remaining production quantity via `_getRemainingProductionQty(...)`
    - blocks if `issue qty > remaining`
- `ExportPage` (in `lib/pages/export.dart`):
  - before saving export, checks:
    - remaining available quantity = issued - exported
    - blocks if `export qty > remaining`

### Stock calculation logic
- File: `lib/services/stock_service.dart`
- `generateReport(fromDate, toDate)`:
  1. Loads purchase orders from `purchase_order`.
     - Uses `po['lines']` to compute **opening** per `(poNo|articleNo|color)`.
  2. Loads issues from `issue` within date range.
     - Adds **issue** qty.
  3. Loads exports from `export` within date range.
     - Adds **export** qty.
  4. Returns `StockReport.calculate(...)` where:
     - `closing = opening + issue - export`

---

## 6) Firestore collections used (as seen in code)

- `master_lc`
- `purchase_order`
- `Production` (note capital P in multiple places)
- `issue`
- `export`
- `activity_log`
- `settings/company_info`

> Some code also references `'Purchase Order'` / `'issue'` / `'Production'` in a way that might not match the exact Firestore collection names; see `DataProvider`.

---

## Notes / Known gaps discovered in code scan
- Cutting and Sewing entities are not present.
- `ERPBusinessEngine` is not present.
- `DataProvider` appears partially unused because pages mostly query Firestore directly.

