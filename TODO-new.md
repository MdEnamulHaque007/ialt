# Task: Fix PO dropdown not showing in ProductionPage new production entry

## Information Gathered:
- production_page.dart has dropdown code for PO No, Article, Color cascading from PO lines.
- Loads from wrong collection 'Purchase Order' (capital) instead of 'purchase_order' (lowercase, as in purchase_order_page.dart).
- Line keys: PO lines use 'article' (not 'articleNo'), 'color', 'unitPrice', 'qty'.
- _loadPurchaseOrders called in _loadData.

## Plan:
**lib/production_page.dart**:
1. Change collection('Purchase Order') to collection('purchase_order').
2. In _getArticleItems/_getColorItems/_getUnitPrice: Change line['articleNo'] to line['article'].
3. Add loading indicator for dropdowns if empty.
4. Ensure _loadData() called on init.

**Dependent files:** None.

## Followup steps:
- Edit file.
- `flutter pub get` if needed.
- `flutter run` to test.
- git add/commit/push.

