import 'package.dart';

class DeliveryListModel {
  final String status;
  final String message;
  final DeliveryListData data;

  DeliveryListModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory DeliveryListModel.fromJson(Map<String, dynamic> json) {
    return DeliveryListModel(
      status: json['status'],
      message: json['message'],
      data: DeliveryListData.fromJson(json['data']),
    );
  }
}

class DeliveryListData {
  final List<DeliveryItem> deliveries;

  DeliveryListData({
    required this.deliveries,
  });

  factory DeliveryListData.fromJson(Map<String, dynamic> json) {
    return DeliveryListData(
      deliveries: (json['deliveries'] as List)
          .map((item) => DeliveryItem.fromJson(item))
          .toList(),
    );
  }
}

class DeliveryItem {
  final String orderNo;
  final List<String> itemsList;
  final String deliveryStatus;
  final String driverId;
  final DateTime? checkInTime;
  final DateTime lastUpdateTime;
  final double totalWeight;
  final String customer;
  final String address;
  final DateTime? checkOutTime;
  final double totalPrice;
  final DateTime deliveryStartTime;
  final String orderNotes;
  final String? trackerId;

  DeliveryItem({
    required this.orderNo,
    required this.itemsList,
    required this.deliveryStatus,
    required this.driverId,
    this.checkInTime,
    required this.lastUpdateTime,
    required this.totalWeight,
    required this.customer,
    required this.address,
    this.checkOutTime,
    required this.totalPrice,
    required this.deliveryStartTime,
    required this.orderNotes,
    this.trackerId,
  });
  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      orderNo: json['orderNo'] ?? '-',
      itemsList:
          json['itemsList'] != null ? List<String>.from(json['itemsList']) : [],
      deliveryStatus: json['deliveryStatus'] ?? 'On Delivery',
      driverId: json['driverId'] ?? '-',
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      lastUpdateTime: json['lastUpdateTime'] != null
          ? DateTime.parse(json['lastUpdateTime'])
          : DateTime.now(),
      totalWeight: json['totalWeight']?.toDouble() ?? 0.0,
      customer: json['customer']?.toString().trim().isEmpty == true
          ? '-'
          : (json['customer'] ?? '-'),
      address: json['address']?.toString().trim().isEmpty == true
          ? '-'
          : (json['address'] ?? '-'),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
      deliveryStartTime: json['deliveryStartTime'] != null
          ? DateTime.parse(json['deliveryStartTime'])
          : DateTime.now(),
      orderNotes: json['orderNotes']?.toString().trim().isEmpty == true
          ? '-'
          : (json['orderNotes'] ?? '-'),
      trackerId: json['trackerId'],
    );
  } // Helper method to convert delivery status to PackageStatus
  PackageStatus get packageStatus {
    // Check if checkOutTime is not null - this means the package was delivered
    if (checkOutTime != null) {
      return PackageStatus.checkout;
    }

    final status = deliveryStatus.trim();

    // Map exact status formats from API
    switch (status) {
      case 'Check-in':
      case 'check-in':
      case 'Check in':
      case 'check in':
      case 'checkin':
      case 'Checked in':
      case 'checked in':
      case 'arrived':
      case 'Arrived':
        return PackageStatus.checkin;

      case 'On Delivery':
      case 'on delivery':
      case 'On-Delivery':
      case 'on-delivery':
      case 'ondelivery':
      case 'OnDelivery':
      case 'delivering':
      case 'Delivering':
      case 'in transit':
      case 'In Transit':
        return PackageStatus.onDelivery;

      case 'Return':
      case 'return':
      case 'Returned':
      case 'returned':
      case 'failed delivery':
      case 'Failed Delivery':
      case 'undelivered':
      case 'Undelivered':
        return PackageStatus.returned;

      case 'Check-out':
      case 'check-out':
      case 'Check out':
      case 'check out':
      case 'checkout':
      case 'Checkout':
      case 'Checked out':
      case 'checked out':
      case 'delivered':
      case 'Delivered':
      case 'completed':
      case 'Completed':
        return PackageStatus.checkout;

      default:
        return PackageStatus.onDelivery;
    }
  }

  // Helper method to get formatted items list
  String get formattedItems {
    if (itemsList.isEmpty) {
      return '-';
    }
    return itemsList.join(', ');
  }
}
