import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class DebtProvider extends ChangeNotifier {
  final ApiService _api;
  List<Map<String, dynamic>> _debts = [];
  List<Map<String, dynamic>> _balances = [];
  bool _isLoading = false;

  DebtProvider(this._api);

  List<Map<String, dynamic>> get debts => _debts;
  List<Map<String, dynamic>> get balances => _balances;
  bool get isLoading => _isLoading;

  Future<void> loadDebts({String show = 'active'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.getDebts(show: show);
      _debts = List<Map<String, dynamic>>.from(result['debts'] ?? []);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSummary() async {
    try {
      final result = await _api.getDebtSummary();
      _balances = List<Map<String, dynamic>>.from(result['balances'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createDebt({
    required int fromUserId,
    required int toUserId,
    required double amount,
    int? billId,
    String description = '',
  }) async {
    try {
      await _api.createDebt(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        billId: billId,
        description: description,
      );
      await loadDebts();
      await loadSummary();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markPaid(int debtId) async {
    try {
      await _api.markDebtPaid(debtId);
      await loadDebts();
      await loadSummary();
      return true;
    } catch (_) {
      return false;
    }
  }
}
