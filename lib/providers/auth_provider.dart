import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'order_provider.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  final ApiService _api;
  bool _isLoading = false;
  OrderProvider? _orderProvider;

  AuthProvider(this._api);

  void setOrderProvider(OrderProvider op) => _orderProvider = op;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    _currentUser = await _api.getCurrentUser();
    if (_currentUser != null) {
      final token = await _api.getToken();
      if (token != null) _orderProvider?.connectWs(token);
    }
    notifyListeners();
  }

  Future<String?> login(String login, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.login(login.trim(), password.trim());
      _currentUser = UserModel.fromMap(result['user']);
      final token = result['token'] as String?;
      if (token != null) _orderProvider?.connectWs(token);
      _isLoading = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Server bilan ulanishda xatolik. Backend ishlaydimi?";
    }
  }

  Future<void> logout() async {
    _orderProvider?.disconnectWs();
    _currentUser = null;
    await _api.logout();
    notifyListeners();
  }
}
