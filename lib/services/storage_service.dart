import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _ordersKey = 'orders';
  static const String _currentUserKey = 'current_user';

  static StorageService? _instance;
  late SharedPreferences _prefs;

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService();
    await _instance!._init();
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth
  Future<void> saveCurrentUser(UserModel user) async {
    await _prefs.setString(_currentUserKey, jsonEncode(user.toMap()));
  }

  Future<UserModel?> getCurrentUser() async {
    final data = _prefs.getString(_currentUserKey);
    if (data == null) return null;
    return UserModel.fromMap(jsonDecode(data));
  }

  Future<void> clearCurrentUser() async {
    await _prefs.remove(_currentUserKey);
  }

  UserModel? authenticate(String login, String password) {
    try {
      return UserModel.hardcodedUsers.firstWhere(
        (u) => u.login == login && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  // Orders
  Future<List<OrderModel>> getOrders() async {
    final data = _prefs.getString(_ordersKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => OrderModel.fromMap(e)).toList();
  }

  Future<void> saveOrders(List<OrderModel> orders) async {
    final data = jsonEncode(orders.map((o) => o.toMap()).toList());
    await _prefs.setString(_ordersKey, data);
  }

  Future<void> addOrder(OrderModel order) async {
    final orders = await getOrders();
    orders.add(order);
    await saveOrders(orders);
  }

  Future<void> updateOrder(OrderModel updated) async {
    final orders = await getOrders();
    final idx = orders.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      orders[idx] = updated;
      await saveOrders(orders);
    }
  }

  Future<void> deleteOrder(String id) async {
    final orders = await getOrders();
    orders.removeWhere((o) => o.id == id);
    await saveOrders(orders);
  }

  List<UserModel> getWorkers() {
    return UserModel.hardcodedUsers.where((u) => u.role == UserRole.worker).toList();
  }

  List<UserModel> getDrivers() {
    return UserModel.hardcodedUsers.where((u) => u.role == UserRole.driver).toList();
  }
}
