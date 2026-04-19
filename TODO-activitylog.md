# ActivityLog Page & Logging

**Information Gathered:**
- main_navigation.dart: Nav drawer IndexedStack
- FirebaseService: Firebase init
- Pages: export.dart, issue.dart, purchase_order_page.dart, production_page.dart have CRUD

**Plan:**
1. lib/firebase_service.dart: Add logActivity
2. lib/activity_log.dart: New page show logs
3. lib/main_navigation.dart: Add nav item
4. Update CRUD pages call logActivity
5. Test

**Dependent Files:**
- firebase_service.dart, main_navigation.dart, activity_log.dart (new), CRUD pages

**Followup:**
- Hot reload, test logs
