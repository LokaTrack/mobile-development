import 'package.dart';
import '../../../utils/datetime_helper.dart';

class DashboardModel {
  final int onDeliveredPackages;
  final int checkedInPackages;
  final int deliveredPackages;
  final int returnedPackages;
  final int others;
  final double percentage;
  final List<RecentOrder> recentOrders;

  DashboardModel({
    required this.onDeliveredPackages,
    required this.checkedInPackages,
    required this.deliveredPackages,
    required this.returnedPackages,
    required this.others,
    required this.percentage,
    required this.recentOrders,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    List<RecentOrder> recentOrders = [];
    if (json['recentOrder'] != null) {
      recentOrders = List<RecentOrder>.from(
          json['recentOrder'].map((order) => RecentOrder.fromJson(order)));
    }

    return DashboardModel(
      onDeliveredPackages: json['onDeliveredPackages'] ?? 0,
      checkedInPackages: json['checkedInPackages'] ?? 0,
      deliveredPackages: json['deliveredPackages'] ?? 0,
      returnedPackages: json['returnedPackages'] ?? 0,
      others: json['others'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      recentOrders: recentOrders,
    );
  }
}

class RecentOrder {
  final String orderNo;
  final String deliveryStatus;
  final String? lastUpdateTime;
  final double totalWeight;
  final String? checkOutTime;
  final double totalPrice;
  final String? deliveryStartTime;
  final String? orderNotes;
  final List<String> itemsList;
  final String? checkInTime;
  final String customer;
  final String address;
  final String trackerId;
  final String? returnTime;
  final String driverId;

  RecentOrder({
    required this.orderNo,
    required this.deliveryStatus,
    this.lastUpdateTime,
    required this.totalWeight,
    this.checkOutTime,
    required this.totalPrice,
    this.deliveryStartTime,
    this.orderNotes,
    required this.itemsList,
    this.checkInTime,
    required this.customer,
    required this.address,
    required this.trackerId,
    this.returnTime,
    required this.driverId,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    List<String> items = [];
    if (json['itemsList'] != null) {
      items = List<String>.from(json['itemsList']);
    }

    return RecentOrder(
      orderNo: json['orderNo'] ?? '',
      deliveryStatus: json['deliveryStatus'] ?? '',
      lastUpdateTime: json['lastUpdateTime'],
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      checkOutTime: json['checkOutTime'],
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      deliveryStartTime: json['deliveryStartTime'],
      orderNotes: json['orderNotes'],
      itemsList: items,
      checkInTime: json['checkInTime'],
      customer: json['customer'] ?? '',
      address: json['address'] ?? '',
      trackerId: json['trackerId'] ?? '',
      returnTime: json['returnTime'],
      driverId: json['driverId'] ?? '',
    );
  }

  // Convert delivery status from API to PackageStatus enum
  PackageStatus getPackageStatus() {
    switch (deliveryStatus.toLowerCase()) {
      case 'on delivery':
        return PackageStatus.onDelivery;
      case 'check-in':
        return PackageStatus.checkin;
      case 'check-out':
        return PackageStatus.checkout;
      case 'return':
        return PackageStatus.returned;
      default:
        return PackageStatus.onDelivery;
    }
  }

  // Method to convert RecentOrder to Package for UI compatibility
  Package toPackage() {
    // Join items for display
    String itemsString = itemsList.join(', ');

    // Parse delivery date using timezone-aware helper
    DateTime deliveryDate =
        DateTimeHelper.parseLocalDateTime(deliveryStartTime) ?? DateTime.now();

    // Parse delivered date if available using timezone-aware helper
    DateTime? deliveredDate;
    if (lastUpdateTime != null) {
      deliveredDate = DateTimeHelper.parseLocalDateTime(lastUpdateTime!);
    }

    return Package(
      id: orderNo,
      recipient: customer,
      address: address,
      status: getPackageStatus(),
      items: itemsString,
      scheduledDelivery: deliveryDate,
      totalAmount: totalPrice.toInt(),
      deliveredAt: deliveredDate,
      weight: totalWeight,
      notes: orderNotes ?? '',
      returningReason: deliveryStatus.toLowerCase() == 'return'
          ? 'Paket dikembalikan'
          : null,
    );
  }
}
