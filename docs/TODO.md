# TODO.md

> Current TODO list derived from scanning the repository.

## 3.1 UI remaining work

### Cutting / Sewing / Production / Issue / Export
- Cutting and Sewing modules are not present as screens/entities in the current codebase.
- Production/Issue/Export screens exist, but dropdown linking for PO/Article/Color is already implemented in current pages:
  - `lib/pages/production_page.dart` implements PO → Article → Color dropdown chain.
  - `lib/pages/issue.dart` implements PO → Article → Color dropdown chain.
  - `lib/pages/export.dart` implements PO → Article → Color dropdown chain.

### Edit/Delete presence
- MasterLC already contains edit/delete.
- PurchaseOrder/Production/Issue/Export pages also include edit/delete dialogs/actions.
- Therefore the “only MasterLC has edit/delete” concern does not match the current code.

## 3.2 Data layer / Firestore migration gaps

### Firestore datasource implementation
- There is a generic `FirestoreService` (`lib/services/firestore_service.dart`).
- However the code in pages primarily uses `FirebaseFirestore.instance` directly.
- If your goal is “Firestore datasource implement (currently memory datasource)”:
  - `lib/providers/data_provider.dart` loads some collections into memory (but it’s not consistently used by pages).
  - Cutting/Sewing entities and their persistence are missing.

### audit_logs collection
- `ActivityLogService` writes to Firestore collection: `activity_log`.
- An `audit_logs` collection is not present in the code; existing naming is `activity_log`.

## 3.3 Performance

### Pagination
- Pagination exists in:
  - `lib/pages/production_page.dart`
  - `lib/pages/issue.dart`
  - `lib/pages/export.dart`
- MasterLC uses a full stream + in-memory filtering/sorting (not paginated).

### Lazy loading
- Current implementations load collections fully in some places:
  - PurchaseOrder/Issue/Export/Production pages often load `.get()` for full collections then filter locally.
- To add lazy loading/pagination at Firestore query level:
  - Replace local filtering + full loads with Firestore `limit`, `startAfter`, and query-based search where possible.

---

## 4. Engineering TODOs found in code

### Missing classes referenced by your earlier requirements
- No `ERPBusinessEngine` class exists in the current codebase.

### Stock calculation is date-range based
- `StockService.generateReport(fromDate, toDate)` computes opening/issue/export within the specified range.
- If you intended “opening before fromDate” (true inventory opening balance), current implementation loads only purchase orders in the full range (because it loads `purchase_order` without date filter).

### Collection naming inconsistencies
- Some parts reference `Production` vs `production` (capitalization matters in Firestore paths).
- `DataProvider` loads `Purchase Order`, `Production`, and `issue` but other pages use `purchase_order`, `Production`, and `issue`.
- This can cause data duplication or missing data depending on how collections were created.

