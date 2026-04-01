import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String get _baseUrl {
    // Android emulator uses 10.0.2.2 to reach host
    // iOS simulator and desktop use localhost
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // --- Auth ---

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register/'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login/'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // --- Bills ---

  Future<Map<String, dynamic>> saveBill({
    required double total,
    required double serviceChargePercent,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> people,
    required Map<String, List<String>> assignments,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bills/'),
      headers: _headers,
      body: jsonEncode({
        'total': total,
        'service_charge_percent': serviceChargePercent,
        'items': items,
        'people': people,
        'assignments': assignments,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserBills() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/bills/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<bool> deleteBill(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/bills/$id/'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  // --- Helpers ---

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['error'] as String? ?? 'Unknown error',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
