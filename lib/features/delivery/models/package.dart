enum PackageStatus { onDelivery, checkin, checkout, returned }

class Package {
  final String id;
  final String recipient;
  final String address;
  final PackageStatus status;
  final String items;
  final DateTime scheduledDelivery;
  final int totalAmount;
  final DateTime? deliveredAt;
  final int? rating;
  final double weight;
  final String notes;
  final String? returningReason;

  Package({
    required this.id,
    required this.recipient,
    required this.address,
    required this.status,
    required this.items,
    required this.scheduledDelivery,
    required this.totalAmount,
    this.deliveredAt,
    this.rating,
    this.weight = 0.0,
    required this.notes,
    this.returningReason,
  });
}
