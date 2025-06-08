/// Enhanced ReturnItem model for Ultimate OCR with auto-check and dynamic pricing support
class EnhancedReturnItem {
  final String itemName;
  final double quantity;
  final double returnQuantity;
  final double unitPrice;
  final double totalPrice;
  final String notes;
  final double confidence;
  final bool shouldAutoCheck;
  final bool apiMatched;
  final String originalText;
  final String cleanedName;
  final String validationWarning;
  final String pricingSource;
  final String weight;
  final Map<String, dynamic>? rawData;

  EnhancedReturnItem({
    required this.itemName,
    required this.quantity,
    required this.returnQuantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes = '',
    this.confidence = 0.0,
    this.shouldAutoCheck = false,
    this.apiMatched = false,
    this.originalText = '',
    this.cleanedName = '',
    this.validationWarning = '',
    this.pricingSource = 'OCR',
    this.weight = '',
    this.rawData,
  });

  /// Create from enhanced OCR processing result
  factory EnhancedReturnItem.fromMap(Map<String, dynamic> map) {
    return EnhancedReturnItem(
      itemName: map['itemName']?.toString() ?? '',
      quantity: _parseDouble(map['quantity']) ?? 0.0,
      returnQuantity: _parseDouble(map['returnQuantity']) ?? 0.0,
      unitPrice: _parseDouble(map['unitPrice']) ?? 0.0,
      totalPrice: _parseDouble(map['totalPrice']) ?? 0.0,
      notes: map['notes']?.toString() ?? '',
      confidence: _parseDouble(map['matchConfidence']) ?? 0.0,
      shouldAutoCheck: map['shouldAutoCheck'] == true,
      apiMatched: map['apiMatched'] == true,
      originalText: map['originalText']?.toString() ?? '',
      cleanedName: map['cleanedName']?.toString() ?? '',
      validationWarning: map['validationWarning']?.toString() ?? '',
      pricingSource: map['pricingSource']?.toString() ?? 'OCR',
      weight: map['weight']?.toString() ?? '',
      rawData: map,
    );
  }

  /// Convert to format used by return confirmation screen with auto-check logic
  Map<String, dynamic> toDisplayFormat() {
    // Use enhanced database name if available, otherwise fallback to cleaned item name
    String displayName = itemName;
    if (rawData != null && rawData!['api_matched_name'] != null) {
      displayName = rawData!['api_matched_name'];
    }

    final safeName = displayName.isNotEmpty ? displayName : 'Unknown Item';
    final safeQuantity = returnQuantity > 0 ? returnQuantity : 1.0;

    // Use enhanced pricing if available
    int safePrice = unitPrice > 0 ? unitPrice.toInt() : 15000;
    if (rawData != null && rawData!['api_matched_price'] != null) {
      safePrice = (rawData!['api_matched_price'] as double).toInt();
    }

    final safeWeight = weight.isNotEmpty ? _parseDouble(weight) ?? 0.5 : 0.5;

    return {
      'id': safeName.hashCode.toString(),
      'name': safeName,
      'qty': quantity,
      'returnQty': safeQuantity,
      'price': safePrice,
      'weight': safeWeight,
      'unitMetrics': safeWeight > 0 ? 'kg' : 'pcs',
      'reason':
          validationWarning.isNotEmpty ? validationWarning : 'Item Return',
      'sku': _generateSku(safeName),
      // Auto-check fields for enhanced UX
      'shouldAutoCheck': shouldAutoCheck,
      'confidence': confidence,
      'apiMatched': apiMatched,
      'pricingSource': pricingSource,
      'originalText': originalText,
      'cleanedName': cleanedName,
    };
  }

  /// Convert to API submission format
  Map<String, dynamic> toApiFormat() {
    return {
      'name': itemName,
      'qty': returnQuantity,
      'returnQty': returnQuantity,
      'price': unitPrice.toInt(),
      'reason':
          validationWarning.isNotEmpty ? validationWarning : 'Item Return',
      'unitMetrics': weight.isNotEmpty ? 'kg' : 'pcs',
    };
  }

  /// Generate SKU from item name
  String _generateSku(String name) {
    if (name.length >= 3) {
      return 'VEG-${name.substring(0, 3).toUpperCase()}';
    }
    return 'VEG-${name.toUpperCase()}';
  }

  /// Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// Create a copy with updated values
  EnhancedReturnItem copyWith({
    String? itemName,
    double? quantity,
    double? returnQuantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
    double? confidence,
    bool? shouldAutoCheck,
    bool? apiMatched,
    String? originalText,
    String? cleanedName,
    String? validationWarning,
    String? pricingSource,
    String? weight,
  }) {
    return EnhancedReturnItem(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      returnQuantity: returnQuantity ?? this.returnQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      shouldAutoCheck: shouldAutoCheck ?? this.shouldAutoCheck,
      apiMatched: apiMatched ?? this.apiMatched,
      originalText: originalText ?? this.originalText,
      cleanedName: cleanedName ?? this.cleanedName,
      validationWarning: validationWarning ?? this.validationWarning,
      pricingSource: pricingSource ?? this.pricingSource,
      weight: weight ?? this.weight,
      rawData: rawData,
    );
  }

  @override
  String toString() {
    return 'EnhancedReturnItem(name: $itemName, returnQty: $returnQuantity, price: $unitPrice, confidence: ${(confidence * 100).toStringAsFixed(1)}%, autoCheck: $shouldAutoCheck, apiMatched: $apiMatched)';
  }
}

/// Enhanced OCR Response model with auto-check support
class EnhancedReturnItemOcrResponse {
  final bool success;
  final List<EnhancedReturnItem> returnItems;
  final double processingTimeSeconds;
  final String debugInfo;
  final String source;
  final int autoCheckedCount;
  final int apiMatchedCount;
  final double averageConfidence;

  EnhancedReturnItemOcrResponse({
    required this.success,
    required this.returnItems,
    required this.processingTimeSeconds,
    this.debugInfo = '',
    this.source = 'Enhanced OCR',
    int? autoCheckedCount,
    int? apiMatchedCount,
    double? averageConfidence,
  })  : autoCheckedCount = autoCheckedCount ??
            returnItems.where((item) => item.shouldAutoCheck).length,
        apiMatchedCount = apiMatchedCount ??
            returnItems.where((item) => item.apiMatched).length,
        averageConfidence = averageConfidence ??
            (returnItems.isNotEmpty
                ? returnItems
                        .map((item) => item.confidence)
                        .reduce((a, b) => a + b) /
                    returnItems.length
                : 0.0);

  /// Convert to legacy format for backward compatibility
  Map<String, dynamic> toLegacyFormat() {
    return {
      'success': success,
      'returnItems': returnItems.map((item) => item.toDisplayFormat()).toList(),
      'processingTimeSeconds': processingTimeSeconds,
      'debugInfo': debugInfo,
      'source': source,
      'enhancedData': {
        'autoCheckedCount': autoCheckedCount,
        'apiMatchedCount': apiMatchedCount,
        'averageConfidence': averageConfidence,
        'totalItems': returnItems.length,
      },
    };
  }

  @override
  String toString() {
    return 'EnhancedReturnItemOcrResponse(success: $success, items: ${returnItems.length}, autoChecked: $autoCheckedCount, apiMatched: $apiMatchedCount, avgConfidence: ${(averageConfidence * 100).toStringAsFixed(1)}%)';
  }
}
