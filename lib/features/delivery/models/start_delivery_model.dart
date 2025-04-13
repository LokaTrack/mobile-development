class StartDeliveryResponse {
  final String status;
  final String message;
  final StartDeliveryData data;

  StartDeliveryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory StartDeliveryResponse.fromJson(Map<String, dynamic> json) {
    return StartDeliveryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: StartDeliveryData.fromJson(json['data'] ?? {}),
    );
  }
}

class StartDeliveryData {
  final String orderNo;
  final String driverId;
  final String customer;
  final String address;
  final List<String> itemsList;
  final double totalWeight;
  final double totalPrice;
  final String deliveryStatus;
  final String trackerId;
  final String deliveryStartTime;
  final String? checkInTime;
  final String? checkOutTime;
  final String lastUpdateTime;
  final String? orderNotes;

  StartDeliveryData({
    required this.orderNo,
    required this.driverId,
    required this.customer,
    required this.address,
    required this.itemsList,
    required this.totalWeight,
    required this.totalPrice,
    required this.deliveryStatus,
    required this.trackerId,
    required this.deliveryStartTime,
    this.checkInTime,
    this.checkOutTime,
    required this.lastUpdateTime,
    this.orderNotes,
  });

  factory StartDeliveryData.fromJson(Map<String, dynamic> json) {
    List<String> items = [];
    if (json['itemsList'] != null) {
      items = List<String>.from(json['itemsList']);
    }

    return StartDeliveryData(
      orderNo: json['orderNo'] ?? '',
      driverId: json['driverId'] ?? '',
      customer: json['customer'] ?? '',
      address: json['address'] ?? '',
      itemsList: items,
      totalWeight: (json['totalWeight'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      deliveryStatus: json['deliveryStatus'] ?? '',
      trackerId: json['trackerId'] ?? '',
      deliveryStartTime: json['deliveryStartTime'] ?? '',
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      lastUpdateTime: json['lastUpdateTime'] ?? '',
      orderNotes: json['orderNotes'],
    );
  }
}
