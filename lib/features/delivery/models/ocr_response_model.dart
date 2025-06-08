class OcrResponse {
  final String status;
  final String message;
  final OcrData data;

  OcrResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OcrResponse.fromJson(Map<String, dynamic> json) {
    return OcrResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: OcrData.fromJson(json['data'] ?? {}),
    );
  }
}

class OcrData {
  final String? filename;
  final String? orderNo;
  final String rawText;
  final double processingTime;

  OcrData({
    this.filename,
    this.orderNo,
    required this.rawText,
    required this.processingTime,
  });

  factory OcrData.fromJson(Map<String, dynamic> json) {
    String? extractedOrderNo = json['orderNo'];

    // Jika orderNo tidak ada dalam response, coba ekstrak dari rawText
    if (extractedOrderNo == null && json['rawText'] != null) {
      extractedOrderNo = extractOrderNumberFromText(json['rawText']);
    }

    return OcrData(
      filename: json['filename'],
      orderNo: extractedOrderNo,
      rawText: json['rawText'] ?? '',
      processingTime: (json['processingTime'] ?? 0.0).toDouble(),
    );
  }

  // Helper method untuk ekstrak order number dari text jika API tidak mengembalikan orderNo
  static String? extractOrderNumberFromText(String? rawText) {
    if (rawText == null) return null;

    // Pattern untuk mencari "Order No : XXX" di dalam text
    final RegExp regExp = RegExp(r'Order No\s*:\s*([^\s\n]+)');
    final Match? match = regExp.firstMatch(rawText);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    return null;
  }
}

// Model for Return Item OCR Response
class ReturnItemOcrResponse {
  final String status;
  final String message;
  final ReturnItemData data;

  ReturnItemOcrResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ReturnItemOcrResponse.fromJson(Map<String, dynamic> json) {
    return ReturnItemOcrResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: ReturnItemData.fromJson(json['data'] ?? {}),
    );
  }
}

class ReturnItemData {
  final List<ReturnItem> itemsData;
  final String rawText;
  final double processingTime;

  ReturnItemData({
    required this.itemsData,
    required this.rawText,
    required this.processingTime,
  });

  factory ReturnItemData.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['itemsData'] as List?)
            ?.map(
              (item) => ReturnItem.fromJson(item),
            )
            .toList() ??
        [];

    return ReturnItemData(
      itemsData: itemsList,
      rawText: json['rawText'] ?? '',
      processingTime: (json['processingTime'] ?? 0.0).toDouble(),
    );
  }
}

class ReturnItem {
  final int number;
  final String item;
  final double quantity;
  final double returnQuantity;

  // Enhanced data storage for API integration results
  Map<String, dynamic>? _enhancedData;

  ReturnItem({
    required this.number,
    required this.item,
    required this.quantity,
    required this.returnQuantity,
    Map<String, dynamic>? enhancedData,
  }) : _enhancedData = enhancedData;
  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      number: json['No'] ?? 0,
      item: json['Item'] ?? '',
      quantity: (json['Qty'] ?? 0.0).toDouble(),
      returnQuantity: (json['Return'] ?? 0.0).toDouble(),
      enhancedData: json['enhancedData'] as Map<String, dynamic>?,
    );
  }

  // Setter for enhanced data
  set enhancedData(Map<String, dynamic>? data) {
    _enhancedData = data;
  }

  // Getter for enhanced data
  Map<String, dynamic>? get enhancedData =>
      _enhancedData; // Convert to format used by the return confirmation screen
  Map<String, dynamic> toDisplayFormat() {
    // Use enhanced data if available, otherwise fall back to defaults
    if (_enhancedData != null) {
      return toEnhancedDisplayFormat(
        dynamicPrice: _enhancedData!['unitPrice'] as double?,
        shouldAutoCheck: _enhancedData!['shouldAutoCheck'] as bool?,
        isApiMatched: _enhancedData!['apiMatched'] as bool?,
        pricingSource: _enhancedData!['pricingSource'] as String?,
        cleanedName: _enhancedData!['cleanedName'] as String?,
      );
    }

    // Fallback to default format
    final safeName = item.isNotEmpty ? item : 'Unknown Item';
    final safeQuantity = returnQuantity > 0 ? returnQuantity : 1.0;

    return {
      'id': safeName.hashCode.toString(),
      'name': safeName,
      'qty': safeQuantity,
      'returnQty': safeQuantity,
      'price': 15000, // Default price for vegetables when not provided by OCR
      'reason': 'Item Return', // Default reason
      'weight': 0.5, // Default weight
      'unitMetrics': 'kg',
      'sku':
          'VEG-${safeName.length >= 3 ? safeName.substring(0, 3).toUpperCase() : safeName.toUpperCase()}',
    };
  }

  // Enhanced display format that preserves dynamic data
  Map<String, dynamic> toEnhancedDisplayFormat({
    double? dynamicPrice,
    bool? shouldAutoCheck,
    bool? isApiMatched,
    String? pricingSource,
    String? cleanedName,
  }) {
    final safeName = (cleanedName?.isNotEmpty == true)
        ? cleanedName!
        : (item.isNotEmpty ? item : 'Unknown Item');
    final safeQuantity = returnQuantity > 0 ? returnQuantity : 1.0;
    final finalPrice = dynamicPrice ?? 15000.0;

    return {
      'id': safeName.hashCode.toString(),
      'name': safeName,
      'qty': safeQuantity,
      'returnQty': safeQuantity,
      'price': finalPrice.toInt(),
      'reason': 'Item Return',
      'weight': 0.5,
      'unitMetrics': 'kg',
      'sku':
          'VEG-${safeName.length >= 3 ? safeName.substring(0, 3).toUpperCase() : safeName.toUpperCase()}',
      // Enhanced metadata
      'shouldAutoCheck': shouldAutoCheck ?? false,
      'isApiMatched': isApiMatched ?? false,
      'pricingSource': pricingSource ?? 'OCR',
      'originalName': item,
      'cleanedName': safeName,
    };
  }
}

// Model for Barcode Scan Response
class BarcodeScanResponse {
  final String status;
  final String message;
  final BarcodeScanData data;

  BarcodeScanResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BarcodeScanResponse.fromJson(Map<String, dynamic> json) {
    return BarcodeScanResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: BarcodeScanData.fromJson(json['data'] ?? {}),
    );
  }
}

class BarcodeScanData {
  final String? url;
  final String? orderNo;
  final double processingTime;

  BarcodeScanData({
    this.url,
    this.orderNo,
    required this.processingTime,
  });

  factory BarcodeScanData.fromJson(Map<String, dynamic> json) {
    return BarcodeScanData(
      url: json['url'],
      orderNo: json['orderNo'],
      processingTime: (json['processingTime'] ?? 0.0).toDouble(),
    );
  }
}
