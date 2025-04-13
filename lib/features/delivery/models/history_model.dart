import '../models/package.dart';

class HistoryResponse {
  final String status;
  final String message;
  final HistoryData data;

  HistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: HistoryData.fromJson(json['data'] ?? {}),
    );
  }
}

class HistoryData {
  final int deliveredPackages;
  final int returnedPackages;
  final int totalDeliveries;
  final List<HistoryItem> history;

  HistoryData({
    required this.deliveredPackages,
    required this.returnedPackages,
    required this.totalDeliveries,
    required this.history,
  });

  factory HistoryData.fromJson(Map<String, dynamic> json) {
    List<HistoryItem> historyItems = [];
    if (json['history'] != null) {
      historyItems = List<HistoryItem>.from(
        json['history'].map((item) => HistoryItem.fromJson(item)),
      );
    }

    return HistoryData(
      deliveredPackages: json['deliveredPackages'] ?? 0,
      returnedPackages: json['returnedPackages'] ?? 0,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      history: historyItems,
    );
  }
}

class HistoryItem {
  final String orderNo;
  final String deliveryStatus;
  final String? checkInTime;
  final String? returnTime;
  final String? lastUpdateTime;
  final double totalWeight;
  final String? checkOutTime;
  final double totalPrice;
  final String? deliveryStartTime;
  final String? orderNotes;
  final List<String> itemsList;
  final String customer;
  final String address;
  final String trackerId;
  final String driverId;

  HistoryItem({
    required this.orderNo,
    required this.deliveryStatus,
    this.checkInTime,
    this.returnTime,
    this.lastUpdateTime,
    required this.totalWeight,
    this.checkOutTime,
    required this.totalPrice,
    this.deliveryStartTime,
    this.orderNotes,
    required this.itemsList,
    required this.customer,
    required this.address,
    required this.trackerId,
    required this.driverId,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    List<String> items = [];
    if (json['itemsList'] != null) {
      items = List<String>.from(json['itemsList'] ?? []);
    }

    return HistoryItem(
      orderNo: json['orderNo'] ?? '',
      deliveryStatus: json['deliveryStatus'] ?? '',
      checkInTime: json['checkInTime'],
      returnTime: json['returnTime'],
      lastUpdateTime: json['lastUpdateTime'],
      totalWeight: (json['totalWeight'] ?? 0.0).toDouble(),
      checkOutTime: json['checkOutTime'],
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      deliveryStartTime: json['deliveryStartTime'],
      orderNotes: json['orderNotes'],
      itemsList: items,
      customer: json['customer'] ?? '',
      address: json['address'] ?? '',
      trackerId: json['trackerId'] ?? '',
      driverId: json['driverId'] ?? '',
    );
  }

  // Convert to Package model for UI compatibility
  Package toPackage() {
    // Determine package status based on deliveryStatus
    PackageStatus status;
    switch (deliveryStatus.toLowerCase()) {
      case 'check-out':
        status = PackageStatus.checkout;
        break;
      case 'check-in':
        status = PackageStatus.checkin;
        break;
      case 'return':
        status = PackageStatus.returned;
        break;
      case 'on delivery':
        status = PackageStatus.onDelivery;
        break;
      default:
        status = PackageStatus.onDelivery;
    }

    // Parse delivery date from delivery start time
    DateTime deliveryDate;
    try {
      deliveryDate = deliveryStartTime != null
          ? DateTime.parse(deliveryStartTime!)
          : DateTime.now();
    } catch (e) {
      deliveryDate = DateTime.now();
    }

    // Parse delivered date from checkout time or last update time
    DateTime? deliveredAt;
    if (checkOutTime != null) {
      try {
        deliveredAt = DateTime.parse(checkOutTime!);
      } catch (e) {
        deliveredAt = null;
      }
    } else if (lastUpdateTime != null && status == PackageStatus.checkout) {
      try {
        deliveredAt = DateTime.parse(lastUpdateTime!);
      } catch (e) {
        deliveredAt = null;
      }
    }

    // Convert items list to comma-separated string
    String itemsString =
        itemsList.isNotEmpty ? itemsList.join(', ') : "No items";

    return Package(
      id: orderNo,
      recipient: customer,
      address: address,
      status: status,
      items: itemsString,
      scheduledDelivery: deliveryDate,
      totalAmount: totalPrice.toInt(),
      deliveredAt: deliveredAt,
      weight: totalWeight,
      notes: orderNotes ?? '',
      returningReason:
          status == PackageStatus.returned ? "Paket dikembalikan" : null,
    );
  }
}
