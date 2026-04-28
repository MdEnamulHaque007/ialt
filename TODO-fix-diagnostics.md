# TODO: Fix All Diagnostics

## Critical Errors (Severity 8)
- [ ] Fix `lib/main.dart` — add missing imports, remove non-existent providers, add `SettingsProvider`
- [ ] Fix `pubspec.yaml` — fix malformed `assets:` key

## Warnings (Severity 2-4)
- [ ] Fix `lib/pages/master_lc_page.dart` — remove unused code, rename `sum` params, replace deprecated `.withOpacity()`
- [ ] Fix `lib/pages/export.dart` — rename `sum` params, replace deprecated `dataRowHeight`
- [ ] Fix `lib/pages/issue.dart` — rename `sum` params, replace deprecated `dataRowHeight`
- [ ] Fix `lib/pages/production_page.dart` — rename `sum` params
- [ ] Fix `lib/pages/purchase_order_page.dart` — rename `sum` params, replace deprecated `.withOpacity()`
- [ ] Fix `lib/pages/login_page.dart` — rename import prefix `myAuth` → `my_auth`
- [ ] Fix `lib/services/firebase_service.dart` — replace `print` with `debugPrint`
- [ ] Fix `lib/services/activity_log_service.dart` — replace `print` with `debugPrint`
- [ ] Fix `lib/services/issue_service.dart` — rename `sum` param
- [ ] Fix `lib/services/master_lc_service.dart` — rename `sum` params
- [ ] Fix `lib/services/production_service.dart` — rename `sum` param
- [ ] Fix `lib/services/purchase_order_service.dart` — rename `sum` params

## Verification
- [ ] Run `flutter analyze` to confirm all diagnostics resolved

