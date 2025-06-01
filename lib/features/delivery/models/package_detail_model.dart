class PackageDetailResponse {
  final String status;
  final String message;
  final PackageDetailData data;

  PackageDetailResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PackageDetailResponse.fromJson(Map<String, dynamic> json) {
    return PackageDetailResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: PackageDetailData.fromJson(json['data'] ?? {}),
    );
  }
}

class PackageDetailData {
  final String orderNo;
  final String orderDate;
  final List<String> itemsList;
  final String phone;
  final double discount;
  final double totalWeight;
  final String customer;
  final String addressMapUrl;
  final double subTotal;
  final String address;
  final String orderNotes;
  final double totalPrice;
  final double shipping;
  final List<PackageDetailItem> items;

  PackageDetailData({
    required this.orderNo,
    required this.orderDate,
    required this.itemsList,
    required this.phone,
    required this.discount,
    required this.totalWeight,
    required this.customer,
    required this.addressMapUrl,
    required this.subTotal,
    required this.address,
    required this.orderNotes,
    required this.totalPrice,
    required this.shipping,
    required this.items,
  });

  factory PackageDetailData.fromJson(Map<String, dynamic> json) {
    List<String> itemsList = [];
    if (json['itemsList'] != null) {
      itemsList = List<String>.from(json['itemsList']);
    }

    List<PackageDetailItem> items = [];
    if (json['items'] != null) {
      items = List<PackageDetailItem>.from(
        json['items'].map((item) => PackageDetailItem.fromJson(item)),
      );
    }

    return PackageDetailData(
      orderNo: json['orderNo'] ?? '',
      orderDate: json['orderDate'] ?? '',
      itemsList: itemsList,
      phone: json['phone'] ?? '',
      discount: (json['discount'] ?? 0.0).toDouble(),
      totalWeight: (json['totalWeight'] ?? 0.0).toDouble(),
      customer: json['customer'] ?? '',
      addressMapUrl: json['addressMapUrl'] ?? '',
      subTotal: (json['subTotal'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      orderNotes: json['orderNotes'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      shipping: (json['shipping'] ?? 0.0).toDouble(),
      items: items,
    );
  }
}

class PackageDetailItem {
  final double weight;
  final String notes;
  final double unitPrice;
  final double total;
  final double quantity;
  final String unitMetrics;
  final String name;

  PackageDetailItem({
    required this.weight,
    required this.notes,
    required this.unitPrice,
    required this.total,
    required this.quantity,
    required this.unitMetrics,
    required this.name,
  });
  factory PackageDetailItem.fromJson(Map<String, dynamic> json) {
    return PackageDetailItem(
      weight: (json['weight'] ?? 0.0).toDouble(),
      notes: json['notes'] ?? '',
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unitMetrics: json['unitMetrics'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
