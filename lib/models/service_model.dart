enum UnitType { sqm, piece, meter }

extension UnitTypeExt on UnitType {
  String get label {
    switch (this) {
      case UnitType.sqm: return 'm²';
      case UnitType.piece: return 'dona';
      case UnitType.meter: return 'metr';
    }
  }

  String get apiValue {
    switch (this) {
      case UnitType.sqm: return 'sqm';
      case UnitType.piece: return 'piece';
      case UnitType.meter: return 'meter';
    }
  }

  static UnitType fromApi(String? v) {
    switch (v) {
      case 'sqm': return UnitType.sqm;
      case 'meter': return UnitType.meter;
      default: return UnitType.piece;
    }
  }
}

class ServiceModel {
  final String id;
  final String name;
  final UnitType unitType;
  final double pricePerUnit;
  final bool isActive;
  final int sortOrder;
  final bool discountEnabled;
  final double discountMinQty;
  final double discountAmount;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.unitType,
    required this.pricePerUnit,
    this.isActive = true,
    this.sortOrder = 0,
    this.discountEnabled = false,
    this.discountMinQty = 0,
    this.discountAmount = 0,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> m) => ServiceModel(
    id: m['id'].toString(),
    name: m['name'] ?? '',
    unitType: UnitTypeExt.fromApi(m['unit_type']),
    pricePerUnit: (m['price_per_unit'] as num?)?.toDouble() ?? 0,
    isActive: (m['is_active'] ?? 1) == 1,
    sortOrder: m['sort_order'] as int? ?? 0,
    discountEnabled: m['discount_enabled'] == 1 || m['discount_enabled'] == true,
    discountMinQty: (m['discount_min_qty'] as num?)?.toDouble() ?? 0,
    discountAmount: (m['discount_amount'] as num?)?.toDouble() ?? 0,
  );
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String serviceId;
  final String serviceName;
  final UnitType unitType;
  final double quantity;
  final double? width;
  final double? height;
  final double? area;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final bool discountEnabled;
  final double discountMinQty;
  final double discountPct; // foiz, masalan 5.0 = 5%

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.serviceId,
    required this.serviceName,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.width,
    this.height,
    this.area,
    this.notes,
    this.discountEnabled = false,
    this.discountMinQty = 0,
    this.discountPct = 0,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> m) => OrderItemModel(
    id: m['id'].toString(),
    orderId: m['order_id'].toString(),
    serviceId: m['service_id'].toString(),
    serviceName: m['service_name'] ?? '',
    unitType: UnitTypeExt.fromApi(m['unit_type']),
    quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
    width: (m['width'] as num?)?.toDouble(),
    height: (m['height'] as num?)?.toDouble(),
    area: (m['area'] as num?)?.toDouble(),
    unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
    totalPrice: (m['total_price'] as num?)?.toDouble() ?? 0,
    notes: m['notes'],
    discountEnabled: m['discount_enabled'] == 1 || m['discount_enabled'] == true,
    discountMinQty: (m['discount_min_qty'] as num?)?.toDouble() ?? 0,
    discountPct: (m['service_discount_pct'] as num?)?.toDouble() ?? 0,
  );

  String get displaySize {
    switch (unitType) {
      case UnitType.sqm:
        if (width != null && height != null) {
          return '${width}m × ${height}m = ${area?.toStringAsFixed(2)}m²';
        }
        return '${quantity.toStringAsFixed(2)} m²';
      case UnitType.meter:
        final match = RegExp(r'^(\d+)(ta|та)$').firstMatch(notes ?? '');
        final count = match?.group(1) ?? '1';
        return '$count ta · ${quantity.toStringAsFixed(0)} m';
      case UnitType.piece:
        return '${quantity.toInt()} ta';
    }
  }
}
