import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _userName;
  String? _userEmail;
  String? _error;
  bool _isGuest = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get error => _error;
  bool get isGuest => _isGuest;
  ApiService get api => _api;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      _api.setToken(token);
      _userName = user['name'] as String;
      _userEmail = user['email'] as String;
      _isLoggedIn = true;
      _isGuest = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Нет подключения к серверу';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.login(email: email, password: password);

      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;

      _api.setToken(token);
      _userName = user['name'] as String;
      _userEmail = user['email'] as String;
      _isLoggedIn = true;
      _isGuest = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Нет подключения к серверу';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void continueAsGuest() {
    _isGuest = true;
    _isLoggedIn = true;
    _userName = 'Гость';
    _error = null;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isGuest = false;
    _userName = null;
    _userEmail = null;
    _api.setToken(null);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
