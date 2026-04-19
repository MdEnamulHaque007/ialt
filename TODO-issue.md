# Task: Fix IssuePage dropdown from Firebase 'Production' collection not showing

## Information Gathered:
- Dropdown cascades PO No → Article → Color from _productions ('Production' collection).
- Getters poNos, articlesForSelectedPo, colorsForSelectedPoArticle filter _productions by _formPoNo/_formArticleNo.
- StatefulBuilder in dialog, onChanged calls setDialogState resetting dependents.
- _loadPurchaseOrders uses 'Purchase Order' (mismatch 'purchase_order').
- Data exists confirmed.

## Plan:
**lib/issue.dart**:
1. Change _loadPurchaseOrders collection('Purchase Order') to collection('purchase_order').
2. Add debugPrint in _loadProductions/_loadData for lengths/check data.
3. Ensure dialog reloads data if needed (call _loadData in _showAddEditDialog).
4. Fix _getUnitPrice lineArticle to 'article'.

**Dependent files:** None.

## Followup steps:
- Edit.
- Hot reload (r in flutter run terminal).
- Check console, test dropdown.
- git commit/push.

