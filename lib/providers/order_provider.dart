import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/carpet_model.dart';
import '../services/api_service.dart';
import '../services/sms_service.dart';
import '../services/ws_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  final ApiService _api;
  final WsService _ws = WsService();
  bool _isLoading = false;
  String? _error;

  // ─── Search / paginated list ──────────────────────────────────────────────
  List<OrderModel> _searchItems = [];
  int _searchTotal = 0;
  int _searchPage = 1;
  bool _searchLoading = false;
  bool _searchLoadingMore = false;
  String _searchQuery = '';
  static const int _pageSize = 20;
  Timer? _debounce;
  bool _disposed = false;

  List<OrderModel> get searchItems => _searchItems;
  int get searchTotal => _searchTotal;
  bool get searchLoading => _searchLoading;
  bool get searchLoadingMore => _searchLoadingMore;
  bool get searchHasMore => _searchItems.length < _searchTotal;
  String get searchQuery => _searchQuery;

  OrderProvider(this._api);

  void connectWs(String token) {
    _ws.addListener(_onWsMessage);
    _ws.connect(token);
  }

  void disconnectWs() {
    _ws.removeListener(_onWsMessage);
    _ws.disconnect();
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'order_created' ||
        type == 'order_updated' ||
        type == 'order_deleted') {
      _refreshSilently();
      _reloadCurrentSearch();
    }
  }

  Future<void> _refreshSilently() async {
    try {
      final data = await _api.getOrders(limit: 500);
      _orders = data['items'] as List<OrderModel>;
      if (_disposed) return;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _reloadCurrentSearch() async {
    try {
      final reloadLimit = (_searchPage * _pageSize).clamp(1, 200);
      final data = await _api.getOrders(
        q: _searchQuery,
        page: 1,
        limit: reloadLimit,
      );
      _searchItems = data['items'] as List<OrderModel>;
      _searchTotal = data['total'] as int;
      _searchPage = (reloadLimit ~/ _pageSize).clamp(1, 99);
      if (_disposed) return;
      notifyListeners();
    } catch (_) {}
  }

  /// Faqat local filter (backend chaqirilmaydi — tez!)
  void setSearch(String q) {
    _searchQuery = q;

    if (q.isEmpty) {
      _searchItems = _orders;
      _searchTotal = _orders.length;
      notifyListeners();
      return;
    }

    // Local filter (0ms)
    final qLower = q.toLowerCase();
    final qClean = q.replaceAll('#', '').replaceAll(RegExp(r'^0+'), '');
    _searchItems = _orders.where((o) {
      return o.customerName.toLowerCase().contains(qLower) ||
             o.phone.contains(q) ||
             o.address.toLowerCase().contains(qLower) ||
             o.id.toString() == qClean;
    }).toList();
    _searchTotal = _searchItems.length;
    notifyListeners();
  }

  Future<void> reloadSearch() => _fetchSearch(reset: true);

  Future<void> loadMoreSearch() async {
    if (_searchLoadingMore || !searchHasMore) return;
    _searchLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _searchPage + 1;
      final data = await _api.getOrders(
        q: _searchQuery,
        page: nextPage,
        limit: _pageSize,
      );
      _searchItems = [..._searchItems, ...(data['items'] as List<OrderModel>)];
      _searchTotal = data['total'] as int;
      _searchPage = nextPage;
    } catch (_) {}
    _searchLoadingMore = false;
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> _fetchSearch({required bool reset}) async {
    if (reset) {
      _searchPage = 1;
      _searchItems = [];
      _searchTotal = 0;
      _searchLoading = true;
      notifyListeners();
    }
    try {
      final data = await _api.getOrders(
        q: _searchQuery,
        page: 1,
        limit: _pageSize,
      );
      _searchItems = data['items'] as List<OrderModel>;
      _searchTotal = data['total'] as int;
      _searchPage = 1;
    } catch (_) {}
    _searchLoading = false;
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<OrderModel> get activeOrders =>
      _orders.where((o) => o.status != OrderStatus.yetkazildi).toList();

  List<OrderModel> get deliveredOrders =>
      _orders.where((o) => o.status == OrderStatus.yetkazildi).toList();

  List<OrderModel> ordersForWorker(String workerId) =>
      _orders.where((o) => o.assignedWorkerId == workerId).toList();

  List<OrderModel> ordersForDriver(String driverId) =>
      _orders.where((o) => o.assignedDriverId == driverId).toList();

  List<OrderModel> ordersForUpakovchik(String upakovchikId) =>
      _orders.where((o) => o.assignedUpakovchikId == upakovchikId).toList();

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getOrders(limit: 500);
      _orders = data['items'] as List<OrderModel>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {}
    if (_searchQuery.isEmpty) {
      _searchItems = _orders;
      _searchTotal = _orders.length;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<OrderModel> addOrder({
    required String customerName,
    required String phone,
    required String address,
    required int carpetCount,
    required String carpetTypes,
    required DateTime pickupDate,
    required DateTime deliveryDate,
    double price = 0,
    String? assignedWorkerId,
    String? assignedDriverId,
    String? notes,
  }) async {
    final data = {
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'carpet_count': carpetCount,
      'carpet_types': carpetTypes,
      'pickup_date': pickupDate.toIso8601String(),
      'delivery_date': deliveryDate.toIso8601String(),
      if (assignedWorkerId != null)
        'assigned_worker_id': int.tryParse(assignedWorkerId),
      if (assignedDriverId != null)
        'assigned_driver_id': int.tryParse(assignedDriverId),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final order = await _api.createOrder(data);
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  /// Returns [SmsResult] when status → tayyor, otherwise null.
  /// [driverId] — tayyor bo'lganda yangi haydovchi tayinlash (ixtiyoriy)
  /// [upakovchikId] — upakovka bo'lganda upakovchik tayinlash (ixtiyoriy)
  Future<SmsResult?> updateOrderStatus(
    String id,
    OrderStatus status, {
    String? driverId,
    String? upakovchikId,
    String? workerId,
  }) async {
    final old = _findOrder(id);
    final body = <String, dynamic>{'status': status.name};
    if (driverId != null) body['assigned_driver_id'] = int.tryParse(driverId);
    if (upakovchikId != null) body['assigned_upakovchik_id'] = int.tryParse(upakovchikId);
    if (workerId != null) body['assigned_worker_id'] = int.tryParse(workerId);

    final updated = await _api.updateOrder(id, body);
    _replaceOrder(updated);
    notifyListeners();

    if (old == null) return null;
    if (old.status != OrderStatus.tayyor && status == OrderStatus.tayyor) {
      final result = await SmsService.sendReadyNotification(phone: updated.phone);
      return result;
    }
    return null;
  }

  Future<void> updatePaymentStatus(String id, PaymentStatus status) async {
    final updated = await _api.updateOrder(id, {'payment_status': status.name});
    _replaceOrder(updated);
    notifyListeners();
  }

  Future<void> setManualPrice(String id, double? price) async {
    final updated = await _api.updateOrder(id, {'manual_price': price});
    _replaceOrder(updated);
    notifyListeners();
  }

  Future<void> saveAdvancePayment(String orderId, double amount) async {
    await _api.saveAdvancePayment(orderId, amount);
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(advancePayment: amount);
    }
    notifyListeners();
  }

  Future<void> collectPayment(String orderId) async {
    final updated = await _api.collectPayment(orderId);
    _replaceOrder(updated);
    notifyListeners();
  }

  Future<void> markAsDebt(String orderId) async {
    final updated = await _api.markAsDebt(orderId);
    _replaceOrder(updated);
    notifyListeners();
  }

  Future<void> claimOrder(String orderId) async {
    final updated = await _api.claimOrder(orderId);
    _replaceOrder(updated);
    notifyListeners();
  }

  Future<void> updateOrder(OrderModel order) async {
    final body = <String, dynamic>{
      'customer_name': order.customerName,
      'phone': order.phone,
      'address': order.address,
      'carpet_count': order.carpetCount,
      'carpet_types': order.carpetTypes,
      'pickup_date': order.pickupDate.toIso8601String(),
      'delivery_date': order.deliveryDate.toIso8601String(),
      'status': order.status.name,
      'payment_status': order.paymentStatus.name,
      if (order.assignedWorkerId != null)
        'assigned_worker_id': int.tryParse(order.assignedWorkerId!),
      if (order.assignedDriverId != null)
        'assigned_driver_id': int.tryParse(order.assignedDriverId!),
      'notes': order.notes,
    };
    final updated = await _api.updateOrder(order.id, body);
    _replaceOrder(updated);
    notifyListeners();
  }

  Future<void> deleteOrder(String id) async {
    await _api.deleteOrder(id);
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  Future<List<CarpetModel>> addCarpetMeasurements(
    String orderId,
    List<Map<String, double>> carpets, {
    double? lat,
    double? lng,
  }) async {
    final result = await _api.addCarpetMeasurements(orderId, carpets, lat: lat, lng: lng);
    final carpetList = (result['carpets'] as List).map((c) => CarpetModel.fromMap(c)).toList();
    final totalPrice = (result['total_price'] as num).toDouble();
    final carpetCount = (result['carpet_count'] as num?)?.toInt();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        totalPrice: totalPrice,
        carpets: carpetList,
        carpetCount: carpetCount ?? carpetList.length,
        pickupLat: lat,
        pickupLng: lng,
      );
    }
    notifyListeners();
    return carpetList;
  }

  Future<List<CarpetModel>> getCarpets(String orderId) async {
    return await _api.getCarpets(orderId);
  }

  OrderModel? _findOrder(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {}
    try {
      return _searchItems.firstWhere((o) => o.id == id);
    } catch (_) {}
    return null;
  }

  void _replaceOrder(OrderModel updated) {
    final idx = _orders.indexWhere((o) => o.id == updated.id);
    if (idx != -1) _orders[idx] = updated;
  }

  // Finance helpers
  double get totalIncome => _orders
      .where((o) => o.paymentStatus == PaymentStatus.tolangan)
      .fold(0.0, (s, o) => s + o.effectivePrice);

  double get pendingIncome => _orders
      .where(
        (o) =>
            o.paymentStatus == PaymentStatus.tolanmagan ||
            o.paymentStatus == PaymentStatus.qarz,
      )
      .fold(0.0, (s, o) => s + o.effectivePrice);

  double get totalRevenue => _orders.fold(0.0, (s, o) => s + o.effectivePrice);

  List<OrderModel> ordersForMonth(int year, int month) => _orders
      .where((o) => o.createdAt.year == year && o.createdAt.month == month)
      .toList();

  List<OrderModel> ordersForDay(DateTime day) => _orders
      .where(
        (o) =>
            o.createdAt.year == day.year &&
            o.createdAt.month == day.month &&
            o.createdAt.day == day.day,
      )
      .toList();

  bool _sameDay(DateTime? dt, int year, int month, int day) =>
      dt != null && dt.year == year && dt.month == month && dt.day == day;

  // To'liq to'langan: (effectivePrice - advance) collectedAt kuni
  // + avans: advancePaymentAt kuni (hali to'lanmagan buyurtmalardan)
  double incomeForDay(DateTime day) {
    double total = 0;
    for (final o in _orders) {
      if (o.paymentStatus == PaymentStatus.tolangan &&
          _sameDay(o.collectedAt, day.year, day.month, day.day)) {
        total += o.effectivePrice - o.advancePayment;
      }
      if (o.advancePayment > 0 &&
          o.paymentStatus != PaymentStatus.tolangan &&
          _sameDay(o.advancePaymentAt, day.year, day.month, day.day)) {
        total += o.advancePayment;
      }
    }
    return total;
  }

  double incomeForMonth(int year, int month) {
    double total = 0;
    for (final o in _orders) {
      if (o.paymentStatus == PaymentStatus.tolangan &&
          o.collectedAt != null &&
          o.collectedAt!.year == year && o.collectedAt!.month == month) {
        total += o.effectivePrice - o.advancePayment;
      }
      if (o.advancePayment > 0 &&
          o.paymentStatus != PaymentStatus.tolangan &&
          o.advancePaymentAt != null &&
          o.advancePaymentAt!.year == year && o.advancePaymentAt!.month == month) {
        total += o.advancePayment;
      }
    }
    return total;
  }

  List<OrderModel> ordersForYear(int year) =>
      _orders.where((o) => o.createdAt.year == year).toList();

  double incomeForYear(int year) {
    double total = 0;
    for (final o in _orders) {
      if (o.paymentStatus == PaymentStatus.tolangan &&
          o.collectedAt != null && o.collectedAt!.year == year) {
        total += o.effectivePrice - o.advancePayment;
      }
      if (o.advancePayment > 0 &&
          o.paymentStatus != PaymentStatus.tolangan &&
          o.advancePaymentAt != null && o.advancePaymentAt!.year == year) {
        total += o.advancePayment;
      }
    }
    return total;
  }

  Map<UserModel, int> workerOrderCounts(List<UserModel> workers) {
    final map = <UserModel, int>{};
    for (final w in workers) {
      map[w] = _orders.where((o) => o.assignedWorkerId == w.id).length;
    }
    return map;
  }
}
