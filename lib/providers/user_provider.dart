import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  final ApiService _api;
  bool _isLoading = false;
  String? _error;

  UserProvider(this._api);

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<UserModel> get workers =>
      _users.where((u) => u.role == UserRole.worker).toList();

  List<UserModel> get drivers =>
      _users.where((u) => u.role == UserRole.driver).toList();

  List<UserModel> get activeWorkers =>
      _users.where((u) => u.role == UserRole.worker && u.isActive).toList();

  List<UserModel> get activeDrivers =>
      _users.where((u) => u.role == UserRole.driver && u.isActive).toList();

  List<UserModel> get upakovchilar =>
      _users.where((u) => u.role == UserRole.upakovchik).toList();

  List<UserModel> get activeUpakovchilar =>
      _users.where((u) => u.role == UserRole.upakovchik && u.isActive).toList();

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _api.getUsers();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Foydalanuvchilarni yuklashda xatolik';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Returns map with created user info including generatedPassword
  Future<Map<String, dynamic>> createUser(String name, String role) async {
    final result = await _api.createUser(name, role);
    final user = UserModel.fromMap(result);
    _users.insert(0, user);
    notifyListeners();
    return result;
  }

  Future<void> deactivateUser(String id) async {
    await _api.deleteUser(id);
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _users[idx] = UserModel.fromMap({
        ..._users[idx].toMap(),
        'is_active': 0,
      });
      notifyListeners();
    }
  }

  Future<void> activateUser(String id) async {
    await _api.activateUser(id);
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _users[idx] = UserModel.fromMap({
        ..._users[idx].toMap(),
        'is_active': 1,
      });
      notifyListeners();
    }
  }
}
