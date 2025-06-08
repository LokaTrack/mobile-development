/// Response model for Paddle OCR API
class PaddleOcrResponse {
  final String status;
  final String message;
  final PaddleOcrData data;

  PaddleOcrResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PaddleOcrResponse.fromJson(Map<String, dynamic> json) {
    return PaddleOcrResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: PaddleOcrData.fromJson(json['data'] ?? {}),
    );
  }
}

class PaddleOcrData {
  final List<PaddleReturnItem> returnItems;
  final List<PaddleReturnItem> matchedItems;
  final List<String> unmatchedOcrItems;
  final List<PaddleDatabaseItem> databaseItems;
  final double processingTime;
  final String allText;

  PaddleOcrData({
    required this.returnItems,
    required this.matchedItems,
    required this.unmatchedOcrItems,
    required this.databaseItems,
    required this.processingTime,
    required this.allText,
  });

  factory PaddleOcrData.fromJson(Map<String, dynamic> json) {
    return PaddleOcrData(
      returnItems: (json['returnItems'] as List<dynamic>?)
              ?.map((item) => PaddleReturnItem.fromJson(item))
              .toList() ??
          [],
      matchedItems: (json['matchedItems'] as List<dynamic>?)
              ?.map((item) => PaddleReturnItem.fromJson(item))
              .toList() ??
          [],
      unmatchedOcrItems: (json['unmatchedOcrItems'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      databaseItems: (json['databaseItems'] as List<dynamic>?)
              ?.map((item) => PaddleDatabaseItem.fromJson(item))
              .toList() ??
          [],
      processingTime: (json['processingTime'] as num?)?.toDouble() ?? 0.0,
      allText: json['allText'] ?? '',
    );
  }
}

class PaddleReturnItem {
  final int no;
  final String name;
  final double weight;
  final double unitPrice;
  final String unitMetrics;
  final String type;
  final double total;
  final double quantity;
  final double ocrQuantity;
  final double returnQuantity;
  final String ocrItemName;

  PaddleReturnItem({
    required this.no,
    required this.name,
    required this.weight,
    required this.unitPrice,
    required this.unitMetrics,
    required this.type,
    required this.total,
    required this.quantity,
    required this.ocrQuantity,
    required this.returnQuantity,
    required this.ocrItemName,
  });

  factory PaddleReturnItem.fromJson(Map<String, dynamic> json) {
    return PaddleReturnItem(
      no: (json['No'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unitMetrics: json['unitMetrics'] ?? '',
      type: json['type'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      ocrQuantity: (json['ocrQuantity'] as num?)?.toDouble() ?? 0.0,
      returnQuantity: (json['returnQuantity'] as num?)?.toDouble() ?? 0.0,
      ocrItemName: json['ocrItemName'] ?? '',
    );
  }

  /// Convert to Map for easier handling in UI
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weight': weight,
      'unitPrice': unitPrice,
      'unitMetrics': unitMetrics,
      'type': type,
      'total': total,
      'quantity': quantity,
      'ocrQuantity': ocrQuantity,
      'returnQuantity': returnQuantity,
      'ocrItemName': ocrItemName,
      'price': unitPrice,
      'isSelected':
          returnQuantity > 0, // Auto-select items with return quantity > 0
      'confidence': 1.0, // High confidence for Paddle OCR results
    };
  }

  /// Format item display text
  String get formattedItemText {
    final weightStr = weight >= 1000
        ? '${(weight / 1000).toStringAsFixed(1)} Kg'
        : '${weight.toInt()} ${unitMetrics}';
    return '$name ($weightStr)';
  }

  /// Format price display
  String get formattedPrice {
    return 'Rp ${unitPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Format total price display
  String get formattedTotal {
    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}

class PaddleDatabaseItem {
  final double weight;
  final double unitPrice;
  final String unitMetrics;
  final String type;
  final double total;
  final double quantity;
  final String name;

  PaddleDatabaseItem({
    required this.weight,
    required this.unitPrice,
    required this.unitMetrics,
    required this.type,
    required this.total,
    required this.quantity,
    required this.name,
  });

  factory PaddleDatabaseItem.fromJson(Map<String, dynamic> json) {
    return PaddleDatabaseItem(
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unitMetrics: json['unitMetrics'] ?? '',
      type: json['type'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] ?? '',
    );
  }
}
