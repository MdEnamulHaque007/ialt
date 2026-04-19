class AppConstants {
  // Firestore collection names
  static const String colPurchaseOrder = 'purchase_order';
  static const String colProduction = 'Production';
  static const String colIssue = 'issue';
  static const String colExport = 'export';
  static const String colActivityLog = 'activity_log';

  // Common field names
  static const String fieldArticle = 'article';
  static const String fieldArticleNo = 'articleNo'; // legacy in some docs
  static const String fieldColor = 'color';
  static const String fieldUnitPrice = 'unitPrice';
  static const String fieldQty = 'qty';
  static const String fieldQuantity = 'quantity';
  static const String fieldPoNo = 'poNo';
  static const String fieldVoucherNo = 'voucherNo';
  static const String fieldDate = 'date';
  static const String fieldCriteria = 'criteria';
  static const String fieldLines = 'lines';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
}
