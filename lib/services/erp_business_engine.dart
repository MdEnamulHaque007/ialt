class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? field;

  ValidationResult({required this.isValid, this.errorMessage, this.field});

  factory ValidationResult.valid() => ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message, [String? field]) =>
      ValidationResult(isValid: false, errorMessage: message, field: field);
}

class ERPBusinessEngine {
  // Production validation
  // Rule: production quantity cannot exceed PO line quantity
  ValidationResult validateProduction({
    required double poQuantity,
    required double requestedQuantity,
  }) {
    if (requestedQuantity > poQuantity) {
      return ValidationResult.invalid(
        'Production quantity ($requestedQuantity) exceeds PO quantity ($poQuantity)',
        'quantity',
      );
    }
    return ValidationResult.valid();
  }

  // Issue validation
  // Rule: alreadyIssuedQuantity + requestedQuantity cannot exceed productionQuantity
  ValidationResult validateIssue({
    required double productionQuantity,
    required double requestedQuantity,
    required double alreadyIssuedQuantity,
  }) {
    final totalAfter = alreadyIssuedQuantity + requestedQuantity;
    if (totalAfter > productionQuantity) {
      return ValidationResult.invalid(
        'Issue quantity ($totalAfter) exceeds Production quantity ($productionQuantity)',
        'quantity',
      );
    }
    return ValidationResult.valid();
  }

  // Export validation
  // Rule: alreadyExportedQuantity + requestedQuantity cannot exceed issuedQuantity
  ValidationResult validateExport({
    required double issuedQuantity,
    required double requestedQuantity,
    required double alreadyExportedQuantity,
  }) {
    final totalAfter = alreadyExportedQuantity + requestedQuantity;
    if (totalAfter > issuedQuantity) {
      return ValidationResult.invalid(
        'Export quantity ($totalAfter) exceeds Issued quantity ($issuedQuantity)',
        'quantity',
      );
    }
    return ValidationResult.valid();
  }
}
