class ReturnDetailModel {
  final String status;
  final String message;
  final ReturnDetailData data;

  ReturnDetailModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ReturnDetailModel.fromJson(Map<String, dynamic> json) {
    return ReturnDetailModel(
      status: json['status'],
      message: json['message'],
      data: ReturnDetailData.fromJson(json['data']),
    );
  }
}

class ReturnDetailData {
  final String orderNo;
  final DateTime returnDate;
  final List<String> deliveryOrderImages;
  final String returnId;
  final int totalItems;
  final List<ReturnedItem> returnedItems;
  final double totalWeight;
  final String reason;
  final double totalPrice;

  ReturnDetailData({
    required this.orderNo,
    required this.returnDate,
    required this.deliveryOrderImages,
    required this.returnId,
    required this.totalItems,
    required this.returnedItems,
    required this.totalWeight,
    required this.reason,
    required this.totalPrice,
  });

  factory ReturnDetailData.fromJson(Map<String, dynamic> json) {
    return ReturnDetailData(
      orderNo: json['orderNo'],
      returnDate: DateTime.parse(json['returnDate']),
      deliveryOrderImages: List<String>.from(json['deliveryOrderImages']),
      returnId: json['returnId'],
      totalItems: json['totalItems'],
      returnedItems: (json['returnedItems'] as List)
          .map((item) => ReturnedItem.fromJson(item))
          .toList(),
      totalWeight: json['totalWeight'].toDouble(),
      reason: json['reason'],
      totalPrice: json['totalPrice'].toDouble(),
    );
  }
}

class ReturnedItem {
  final String unitName;
  final int quantity;
  final String unitMetrics;
  final double total;
  final double unitPrice;
  final double weight;

  ReturnedItem({
    required this.unitName,
    required this.quantity,
    required this.unitMetrics,
    required this.total,
    required this.unitPrice,
    required this.weight,
  });

  factory ReturnedItem.fromJson(Map<String, dynamic> json) {
    return ReturnedItem(
      unitName: json['unitName'],
      quantity: json['quantity'],
      unitMetrics: json['unitMetrics'],
      total: json['total'].toDouble(),
      unitPrice: json['unitPrice'].toDouble(),
      weight: json['weight'].toDouble(),
    );
  }
}
