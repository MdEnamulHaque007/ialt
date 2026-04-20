class StockReport {
  final String poNo;
  final String articleNo;
  final String color;
  final double opening;
  final double issue;
  final double export;
  final double closing;

  StockReport({
    required this.poNo,
    required this.articleNo,
    required this.color,
    required this.opening,
    required this.issue,
    required this.export,
    required this.closing,
  });

  // closing = opening + issue(FG declaration) - export
  factory StockReport.calculate({
    required String poNo,
    required String articleNo,
    required String color,
    required double opening,
    required double issue,
    required double export,
  }) {
    final closing = opening + issue - export;
    return StockReport(
      poNo: poNo,
      articleNo: articleNo,
      color: color,
      opening: opening,
      issue: issue,
      export: export,
      closing: closing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'poNo': poNo,
      'articleNo': articleNo,
      'color': color,
      'opening': opening,
      'issue': issue,
      'export': export,
      'closing': closing,
    };
  }

  bool get hasNegativeClosing => closing < 0;
  bool get isBalanced => closing == 0;

  @override
  String toString() =>
      'StockReport(poNo: $poNo, article: $articleNo, '
      'color: $color, closing: $closing)';
}
