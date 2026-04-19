# Task: Add production qty validation in IssuePage _saveOrUpdateIssue

**Info Gathered:** 
- Use _productions list from 'Production'.
- For selected _formPoNo/_formArticleNo/_formColor, sum 'quantity' from matching productions.
- Compare with form qty - if issue qty > remaining production qty, show warning, prevent submit.

**Plan:**
lib/issue.dart:
1. Add double _getRemainingProductionQty(String poNo, String articleNo, String color) {
   double prodQty = 0;
   double issuedQty = 0;
   // Sum prod qty
   for (var prod in _productions.where((p) => p['poNo'] == poNo && p['articleNo'] == articleNo && p['color'] == color)) {
     prodQty += (prod['quantity'] ?? 0).toDouble();
   }
   // Sum existing issue qty
   for (var issue in _issues.where((i) => i['poNo'] == poNo && i['articleNo'] == articleNo && i['color'] == color)) {
     issuedQty += (issue['quantity'] ?? 0).toDouble();
   }
   return prodQty - issuedQty;
}
2. In _saveOrUpdateIssue before save:
   double remaining = _getRemainingProductionQty(_formPoNo!, _formArticleNo!, _formColor!);
   if (qty > remaining) {
     ScaffoldMessenger.showSnackBar(SnackBar(content: Text('Issue qty $qty > remaining production ${remaining.toStringAsFixed(0)}. Entry blocked.')));
     return;
   }

**Followup:** Edit, hot reload.


