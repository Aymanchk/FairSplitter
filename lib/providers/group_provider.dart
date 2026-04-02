import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class GroupProvider extends ChangeNotifier {
  final ApiService _api;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;

  GroupProvider(this._api);

  List<Map<String, dynamic>> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.getGroups();
      _groups = List<Map<String, dynamic>>.from(result['groups'] ?? []);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createGroup({
    required String name,
    required List<int> memberIds,
  }) async {
    try {
      await _api.createGroup(name: name, memberIds: memberIds);
      await loadGroups();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateGroup({
    required int groupId,
    String? name,
    List<int>? memberIds,
  }) async {
    try {
      await _api.updateGroup(
        groupId: groupId,
        name: name,
        memberIds: memberIds,
      );
      await loadGroups();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteGroup(int groupId) async {
    try {
      await _api.deleteGroup(groupId);
      await loadGroups();
      return true;
    } catch (_) {
      return false;
    }
  }
}
