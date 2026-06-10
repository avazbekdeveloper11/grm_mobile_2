import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/carpet_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const String _baseUrl =
      'http://xnc9fjs58xbbiimup042ie3w.178.104.171.171.sslip.io';

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';

  String? _token;
  SharedPreferences? _prefs;
  String _language = 'latin';

  static ApiService? _instance;

  // Chuck for debugging HTTP requests
  late final Dio _dio;

  static Future<ApiService> getInstance() async {
    _instance ??= ApiService._();
    await _instance!._init();
    return _instance!;
  }

  ApiService._() {
    _dio = Dio(BaseOptions(baseUrl: '$_baseUrl/api'));
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString(_tokenKey);
  }

  // ─── Auth helpers ───────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    _token = token;
    await _prefs!.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
  }

  Future<void> saveCurrentUser(UserModel user) async {
    await _prefs!.setString(_userKey, jsonEncode(user.toMap()));
  }

  Future<UserModel?> getCurrentUser() async {
    final data = _prefs!.getString(_userKey);
    if (data == null) return null;
    return UserModel.fromMap(jsonDecode(data));
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;
  Future<String?> getToken() async => _token;

  // ─── HTTP helpers ───────────────────────────────────────────────────────────

  static const _appVersion = '2.1.1';

  void setLanguage(String lang) => _language = lang;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-App-Version': _appVersion,
    'X-Language': _language,
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  VoidCallback? onUnauthorized;
  void Function(String message)? onOutdated;

  Options get _dioOptions => Options(headers: _headers);

  dynamic _handleDioResponse(Response response) {
    final body = response.data;
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return body;
    }
    final msg = body is Map ? (body['error'] ?? 'Xatolik') : 'Xatolik';
    if (response.statusCode == 401) onUnauthorized?.call();
    if (response.statusCode == 426) onOutdated?.call(msg.toString());
    throw ApiException(msg.toString(), response.statusCode);
  }

  dynamic _handleDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final body = response.data;
      final msg = body is Map ? (body['error'] ?? 'Xatolik') : 'Xatolik';
      if (response.statusCode == 401) onUnauthorized?.call();
      if (response.statusCode == 426) onOutdated?.call(msg.toString());
      throw ApiException(msg.toString(), response.statusCode);
    }
    throw ApiException(e.message ?? 'Tarmoq xatosi');
  }

  Future<dynamic> get(String path) async {
    try {
      final res = await _dio.get(path, options: _dioOptions);
      return _handleDioResponse(res);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(path, data: data, options: _dioOptions);
      return _handleDioResponse(res);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put(path, data: data, options: _dioOptions);
      return _handleDioResponse(res);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await _dio.delete(path, options: _dioOptions);
      return _handleDioResponse(res);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── Auth ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String login, String password) async {
    final result = await post('/login', {'login': login, 'password': password});
    await saveToken(result['token']);
    final user = UserModel.fromMap(result['user']);
    await saveCurrentUser(user);
    return result;
  }

  Future<void> logout() async {
    await clearToken();
  }

  // ─── Users ──────────────────────────────────────────────────────────────────

  Future<List<UserModel>> getUsers({String? role}) async {
    final path = role != null ? '/users?role=$role' : '/users';
    final List data = await get(path);
    return data.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> createUser(String name, String role) async {
    final result = await post('/users', {'name': name, 'role': role});
    return result;
  }

  Future<void> deleteUser(String id) async {
    await delete('/users/$id');
  }

  Future<void> activateUser(String id) async {
    await put('/users/$id/activate', {});
  }

  // ─── Settings ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSettings() async {
    return await get('/settings');
  }

  Future<Map<String, dynamic>> updateSettings(double pricePerSqm) async {
    return await put('/settings', {'price_per_sqm': pricePerSqm});
  }

  Future<void> updateDiscountSettings({
    required bool enabled,
    required double minSqm,
    required double amount,
    double percentage = 0,
    double stepSqm = 10,
  }) async {
    await put('/settings', {
      'discount_enabled': enabled,
      'discount_min_sqm': minSqm,
      'discount_amount': amount,
      'discount_percentage': percentage,
      'discount_step_sqm': stepSqm,
    });
  }

  Future<void> updateSmsSettings(String email, String password) async {
    await put('/settings', {'eskiz_email': email, 'eskiz_password': password});
  }

  Future<void> updateWorkerSalaryPercent(double percent) async {
    await put('/settings', {'worker_salary_percent': percent});
  }

  Future<List<Map<String, dynamic>>> getSalaryPercentHistory() async {
    final List data = await get('/settings/salary-percent-history');
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> updateSmsEnabled(bool enabled) async {
    await put('/settings', {'sms_enabled': enabled});
  }

  Future<void> updateSmsTemplate(String template) async {
    await put('/settings', {'sms_template': template});
  }

  Future<void> testSms(String phone) async {
    await post('/settings/sms-test', {'phone': phone});
  }

  // Save FCM token
  // ─── Services ──────────────────────────────────────────────────────────────
  Future<List<dynamic>> getServices() async => await get('/services');

  Future<Map<String, dynamic>> createService(
    String name,
    String unitType,
    double price, {
    bool discountEnabled = false,
    double discountMinQty = 0,
    double discountAmount = 0,
  }) async => await post('/services', {
    'name': name,
    'unit_type': unitType,
    'price_per_unit': price,
    'discount_enabled': discountEnabled,
    'discount_min_qty': discountMinQty,
    'discount_amount': discountAmount,
  });

  Future<Map<String, dynamic>> updateService(
    String id,
    Map<String, dynamic> data,
  ) async => await put('/services/$id', data);

  Future<void> deleteService(String id) async => await delete('/services/$id');

  Future<List<dynamic>> getOrderItems(String orderId) async =>
      await get('/services/order/$orderId/items');

  /// Worker'ning barcha order items olish
  /// Qaytaradi: {orderId: [items...], ...}
  Future<Map<String, List<dynamic>>> getWorkerOrderItems(
    String workerId,
  ) async {
    final result = await get('/services/worker/$workerId/items');
    return (result as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).cast<dynamic>()),
    );
  }

  Future<Map<String, dynamic>> saveOrderItems(
    String orderId,
    List<Map<String, dynamic>> items,
  ) async => await post('/services/order/$orderId/items', {'items': items});

  Future<void> savePickupLocation(
    String orderId,
    double lat,
    double lng,
  ) async => await post('/orders/$orderId/carpets', {
    'carpets': [],
    'pickup_lat': lat,
    'pickup_lng': lng,
  });

  Future<Map<String, dynamic>> getUserPassword(String userId) async {
    return await get('/users/$userId/password');
  }

  Future<void> saveFcmToken(String token) async {
    await put('/users/fcm-token', {'token': token});
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await put('/users/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // Driver saves advance payment
  Future<void> saveAdvancePayment(String orderId, double amount) async =>
      await post('/orders/$orderId/advance-payment', {
        'advance_payment': amount,
      });

  // Driver collects payment
  Future<OrderModel> collectPayment(String orderId) async {
    final result = await post('/orders/$orderId/collect', {});
    return OrderModel.fromMap(result);
  }

  // Driver marks order as debt (qarzga)
  Future<OrderModel> markAsDebt(String orderId) async {
    final result = await post('/orders/$orderId/debt', {});
    return OrderModel.fromMap(result);
  }

  // Driver claims an unassigned pickup/delivery order ("Qabul qildim")
  Future<OrderModel> claimOrder(String orderId) async {
    final result = await post('/orders/$orderId/claim', {});
    return OrderModel.fromMap(result);
  }

  // Admin: driver collections report
  Future<Map<String, dynamic>> getDriverCollections({String? date}) async {
    final path = date != null
        ? '/orders/drivers/collections?date=$date'
        : '/orders/drivers/collections';
    return await get(path);
  }

  // Settlements
  Future<List<dynamic>> getDriverBalances() async {
    return await get('/settlements/balances');
  }

  Future<Map<String, dynamic>> getDriverHistory(String driverId) async {
    return await get('/settlements/driver/$driverId');
  }

  Future<Map<String, dynamic>> addSettlement(
    String driverId,
    double amount, {
    String? note,
  }) async {
    return await post('/settlements', {
      'driver_id': int.parse(driverId),
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> deleteSettlement(String id) async {
    await delete('/settlements/$id');
  }

  // ─── Orders ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOrders({
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (q != null && q.isNotEmpty) 'q': q,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final Map<String, dynamic> data = await get('/orders?$query');
    final List items = data['items'] as List;
    return {
      'items': items.map((e) => OrderModel.fromMap(e)).toList(),
      'total': data['total'] as int,
      'page': data['page'] as int,
      'limit': data['limit'] as int,
    };
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final result = await post('/orders', data);
    return OrderModel.fromMap(result);
  }

  Future<OrderModel> updateOrder(String id, Map<String, dynamic> data) async {
    final result = await put('/orders/$id', data);
    return OrderModel.fromMap(result);
  }

  Future<void> deleteOrder(String id) async {
    await delete('/orders/$id');
  }

  // ─── Carpets ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addCarpetMeasurements(
    String orderId,
    List<Map<String, double>> carpets, {
    double? lat,
    double? lng,
  }) async {
    return await post('/orders/$orderId/carpets', {
      'carpets': carpets,
      'pickup_lat': ?lat,
      'pickup_lng': ?lng,
    });
  }

  Future<List<CarpetModel>> getCarpets(String orderId) async {
    final List data = await get('/orders/$orderId/carpets');
    return data.map((e) => CarpetModel.fromMap(e)).toList();
  }

  // ─── Workers (from storage, for offline display) ───────────────────────────

  List<UserModel> getWorkersFromHardcoded() =>
      UserModel.hardcodedUsers.where((u) => u.role == UserRole.worker).toList();

  List<UserModel> getDriversFromHardcoded() =>
      UserModel.hardcodedUsers.where((u) => u.role == UserRole.driver).toList();
}
