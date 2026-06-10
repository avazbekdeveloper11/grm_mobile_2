import 'carpet_model.dart';
import '../l10n/strings.dart';

enum OrderStatus {
  yangi,
  qabulQilindi,
  yuvilyapti,
  upakovka,
  tayyor,
  yetkazildi,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.yangi:
        return 'Yangi';
      case OrderStatus.qabulQilindi:
        return 'Navbat';
      case OrderStatus.yuvilyapti:
        return 'Yuvilyapti';
      case OrderStatus.upakovka:
        return 'Upakovka';
      case OrderStatus.tayyor:
        return 'Tayyor';
      case OrderStatus.yetkazildi:
        return 'Yetkazildi';
    }
  }

  String labelOf(S s) {
    switch (this) {
      case OrderStatus.yangi:       return s.statusYangi;
      case OrderStatus.qabulQilindi: return s.statusQabul;
      case OrderStatus.yuvilyapti:  return s.statusYuvilyapti;
      case OrderStatus.upakovka:    return s.statusUpakovka;
      case OrderStatus.tayyor:      return s.statusTayyor;
      case OrderStatus.yetkazildi:  return s.statusYetkazildi;
    }
  }

  int get colorValue {
    switch (this) {
      case OrderStatus.yangi:
        return 0xFF2196F3;
      case OrderStatus.qabulQilindi:
        return 0xFFFF9800;
      case OrderStatus.yuvilyapti:
        return 0xFF9C27B0;
      case OrderStatus.upakovka:
        return 0xFFFF5722;
      case OrderStatus.tayyor:
        return 0xFF4CAF50;
      case OrderStatus.yetkazildi:
        return 0xFF607D8B;
    }
  }
}

enum PaymentStatus { tolanmagan, tolangan, qarz }

extension PaymentStatusExtension on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.tolangan: return "To'langan";
      case PaymentStatus.qarz: return "Qarz";
      default: return "To'lanmagan";
    }
  }
  String labelOf(S s) {
    switch (this) {
      case PaymentStatus.tolangan: return s.paid;
      case PaymentStatus.qarz: return "Qarz";
      default: return s.unpaid;
    }
  }
}

const _sentinel = Object();

class OrderModel {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final int carpetCount;
  final String carpetTypes;
  final DateTime pickupDate;
  final DateTime deliveryDate;
  final double price;
  final double totalPrice;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String? assignedWorkerId;
  final String? assignedDriverId;
  final String? assignedUpakovchikId;
  final DateTime createdAt;
  final String? notes;
  final List<CarpetModel>? carpets;
  final double? pickupLat;
  final double? pickupLng;
  final String? collectedBy;
  final DateTime? collectedAt;
  final ItemsSummary? itemsSummary;
  final double discountAmount;
  final double advancePayment;
  final DateTime? advancePaymentAt;
  final double? manualPrice;
  final String? telegramChatId;
  final DateTime? washedAt;
  final DateTime? washingStartedAt;
  final DateTime? assignedWorkerAt;

  bool get fromBot => telegramChatId != null && telegramChatId!.isNotEmpty;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.carpetCount,
    required this.carpetTypes,
    required this.pickupDate,
    required this.deliveryDate,
    required this.price,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.assignedWorkerId,
    this.assignedDriverId,
    this.assignedUpakovchikId,
    this.notes,
    this.totalPrice = 0,
    this.carpets,
    this.pickupLat,
    this.pickupLng,
    this.collectedBy,
    this.collectedAt,
    this.itemsSummary,
    this.discountAmount = 0,
    this.advancePayment = 0,
    this.advancePaymentAt,
    this.manualPrice,
    this.telegramChatId,
    this.washedAt,
    this.washingStartedAt,
    this.assignedWorkerAt,
  });

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? address,
    int? carpetCount,
    String? carpetTypes,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    double? price,
    double? totalPrice,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? assignedWorkerId,
    String? assignedDriverId,
    String? assignedUpakovchikId,
    DateTime? createdAt,
    String? notes,
    List<CarpetModel>? carpets,
    double? pickupLat,
    double? pickupLng,
    double? advancePayment,
    DateTime? advancePaymentAt,
    Object? manualPrice = _sentinel,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      carpetCount: carpetCount ?? this.carpetCount,
      carpetTypes: carpetTypes ?? this.carpetTypes,
      pickupDate: pickupDate ?? this.pickupDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedUpakovchikId: assignedUpakovchikId ?? this.assignedUpakovchikId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      carpets: carpets ?? this.carpets,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      discountAmount: discountAmount,
      collectedBy: collectedBy,
      collectedAt: collectedAt,
      itemsSummary: itemsSummary,
      advancePayment: advancePayment ?? this.advancePayment,
      advancePaymentAt: advancePaymentAt ?? this.advancePaymentAt,
      manualPrice: manualPrice == _sentinel ? this.manualPrice : manualPrice as double?,
      telegramChatId: telegramChatId,
      washedAt: washedAt,
      washingStartedAt: washingStartedAt,
      assignedWorkerAt: assignedWorkerAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_name': customerName,
        'phone': phone,
        'address': address,
        'carpet_count': carpetCount,
        'carpet_types': carpetTypes,
        'pickup_date': pickupDate.toIso8601String(),
        'delivery_date': deliveryDate.toIso8601String(),
        'total_price': totalPrice,
        'status': status.name,
        'payment_status': paymentStatus.name,
        'assigned_worker_id': assignedWorkerId,
        'assigned_driver_id': assignedDriverId,
        'assigned_upakovchik_id': assignedUpakovchikId,
        'created_at': createdAt.toIso8601String(),
        'notes': notes,
        'advance_payment_at': advancePaymentAt?.toIso8601String(),
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'].toString(),
        customerName: map['customer_name'] ?? map['customerName'] ?? '',
        phone: map['phone'] ?? '',
        address: map['address'] ?? '',
        carpetCount: (map['carpet_count'] ?? map['carpetCount'] ?? 1) as int,
        carpetTypes: map['carpet_types'] ?? map['carpetTypes'] ?? '',
        pickupDate: DateTime.parse(map['pickup_date'] ?? map['pickupDate'] ?? DateTime.now().toIso8601String()),
        deliveryDate: DateTime.parse(map['delivery_date'] ?? map['deliveryDate'] ?? DateTime.now().toIso8601String()),
        price: ((map['total_price'] ?? map['price'] ?? 0) as num).toDouble(),
        totalPrice: ((map['total_price'] ?? 0) as num).toDouble(),
        status: OrderStatus.values.firstWhere(
          (s) => s.name == (map['status'] ?? 'yangi'),
          orElse: () => OrderStatus.yangi,
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (s) => s.name == (map['payment_status'] ?? map['paymentStatus'] ?? 'tolanmagan'),
          orElse: () => PaymentStatus.tolanmagan,
        ),
        assignedWorkerId: map['assigned_worker_id']?.toString() ?? map['assignedWorkerId']?.toString(),
        assignedDriverId: map['assigned_driver_id']?.toString() ?? map['assignedDriverId']?.toString(),
        assignedUpakovchikId: map['assigned_upakovchik_id']?.toString() ?? map['assignedUpakovchikId']?.toString(),
        createdAt: DateTime.parse(map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()),
        notes: map['notes'],
        carpets: map['carpets'] != null
            ? (map['carpets'] as List).map((c) => CarpetModel.fromMap(c)).toList()
            : null,
        pickupLat: (map['pickup_lat'] as num?)?.toDouble(),
        pickupLng: (map['pickup_lng'] as num?)?.toDouble(),
        discountAmount: ((map['discount_amount'] ?? 0) as num).toDouble(),
        advancePayment: ((map['advance_payment'] ?? 0) as num).toDouble(),
        advancePaymentAt: map['advance_payment_at'] != null
            ? DateTime.tryParse(map['advance_payment_at'])
            : null,
        manualPrice: (map['manual_price'] as num?)?.toDouble(),
        telegramChatId: map['telegram_chat_id']?.toString(),
        washedAt: map['washed_at'] != null
            ? DateTime.tryParse(map['washed_at'])
            : null,
        washingStartedAt: map['washing_started_at'] != null
            ? DateTime.tryParse(map['washing_started_at'])
            : null,
        assignedWorkerAt: map['assigned_worker_at'] != null
            ? DateTime.tryParse(map['assigned_worker_at'])
            : null,
        collectedBy: map['collected_by']?.toString(),
        collectedAt: map['collected_at'] != null
            ? DateTime.tryParse(map['collected_at'])
            : null,
        itemsSummary: map['items_summary'] != null
            ? ItemsSummary.fromMap(map['items_summary'] as Map<String, dynamic>)
            : null,
      );

  // manualPrice bo'lsa uni ishlat, bo'lmasa hisoblab chiqarilgan totalPrice
  double get effectivePrice => manualPrice ?? totalPrice;
}

class ItemsSummary {
  final double totalSqm;
  final double totalMeter;
  final double totalPiece;
  final int itemsCount;

  const ItemsSummary({
    required this.totalSqm,
    required this.totalMeter,
    required this.totalPiece,
    required this.itemsCount,
  });

  factory ItemsSummary.fromMap(Map<String, dynamic> m) => ItemsSummary(
        totalSqm: (m['total_sqm'] as num?)?.toDouble() ?? 0,
        totalMeter: (m['total_meter'] as num?)?.toDouble() ?? 0,
        totalPiece: (m['total_piece'] as num?)?.toDouble() ?? 0,
        itemsCount: (m['items_count'] as num?)?.toInt() ?? 0,
      );

  // "12.5 m²  •  3 dona" ko'rinishida
  String get displayText {
    final parts = <String>[];
    if (totalSqm > 0) parts.add('${totalSqm.toStringAsFixed(2)} m²');
    if (totalMeter > 0) parts.add('${totalMeter.toStringAsFixed(1)} m');
    if (totalPiece > 0) parts.add('${totalPiece.toInt()} dona');
    return parts.isEmpty ? '' : parts.join('  •  ');
  }

  bool get hasItems => itemsCount > 0;
}
