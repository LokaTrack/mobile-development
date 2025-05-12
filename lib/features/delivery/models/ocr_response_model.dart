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
