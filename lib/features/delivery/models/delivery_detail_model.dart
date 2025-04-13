import 'package:flutter/foundation.dart';
import '../models/package.dart';

class DeliveryDetailResponse {
  final String status;
  final String message;
  final DeliveryDetailData data;

  DeliveryDetailResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory DeliveryDetailResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryDetailResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: DeliveryDetailData.fromJson(json['data'] ?? {}),
    );
  }
}

class DeliveryDetailData {
  final String orderNo;
  final String deliveryStatus;
  final String? lastUpdateTime;
  final double totalWeight;
  final String? checkOutTime;
  final double totalPrice;
  final String? deliveryStartTime;
  final String? orderNotes;
  final String itemsList;
  final String? checkInTime;
  final String customer;
  final String address;
  final String trackerId;
  final String driverId;

  DeliveryDetailData({
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
    required this.driverId,
  });

  factory DeliveryDetailData.fromJson(Map<String, dynamic> json) {
    return DeliveryDetailData(
      orderNo: json['orderNo'] ?? '',
      deliveryStatus: json['deliveryStatus'] ?? '',
      lastUpdateTime: json['lastUpdateTime'],
      totalWeight: (json['totalWeight'] ?? 0.0).toDouble(),
      checkOutTime: json['checkOutTime'],
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      deliveryStartTime: json['deliveryStartTime'],
      orderNotes: json['orderNotes'],
      itemsList: json['itemsList'] ?? '',
      checkInTime: json['checkInTime'],
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

    // Parse delivery date from delivery start time with proper error handling
    DateTime deliveryDate = DateTime.now();
    if (deliveryStartTime != null) {
      try {
        deliveryDate = DateTime.parse(deliveryStartTime!);
      } catch (e) {
        print('Error parsing deliveryStartTime: $e');
      }
    }

    // Parse delivered date from checkout time or last update time
    DateTime? deliveredAt;
    if (checkOutTime != null) {
      try {
        deliveredAt = DateTime.parse(checkOutTime!);
      } catch (e) {
        print('Error parsing checkOutTime: $e');
      }
    } else if (lastUpdateTime != null && status == PackageStatus.checkout) {
      try {
        deliveredAt = DateTime.parse(lastUpdateTime!);
      } catch (e) {
        print('Error parsing lastUpdateTime: $e');
      }
    }

    return Package(
      id: orderNo,
      recipient: customer,
      address: address,
      status: status,
      items: itemsList,
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
