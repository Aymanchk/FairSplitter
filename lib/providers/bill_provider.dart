import 'package:flutter/foundation.dart';
import '../models/bill_item.dart';
import '../models/person.dart';

class BillProvider extends ChangeNotifier {
  final List<BillItem> _items = [];
  final List<Person> _people = [];
  double _serviceChargePercent = 10.0;
  bool _serviceChargeEnabled = true;
  final Map<String, Set<String>> _assignments = {};
  int _nextItemId = 0;
  int _nextPersonId = 0;

  List<BillItem> get items => List.unmodifiable(_items);
  List<Person> get people => List.unmodifiable(_people);
  double get serviceChargePercent => _serviceChargePercent;
  bool get serviceChargeEnabled => _serviceChargeEnabled;
  Map<String, Set<String>> get assignments =>
      _assignments.map((k, v) => MapEntry(k, Set.unmodifiable(v)));

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.price);

  double get serviceChargeAmount =>
      _serviceChargeEnabled ? subtotal * _serviceChargePercent / 100 : 0;

  double get total => subtotal + serviceChargeAmount;

  // --- Items ---

  void addItem(String name, double price) {
    _items.add(BillItem(
      id: 'item_${_nextItemId++}',
      name: name,
      price: price,
    ));
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _assignments.remove(itemId);
    notifyListeners();
  }

  void addItemsFromOcr(List<Map<String, dynamic>> ocrItems) {
    for (final item in ocrItems) {
      _items.add(BillItem(
        id: 'item_${_nextItemId++}',
        name: item['name'] as String,
        price: (item['price'] as num).toDouble(),
      ));
    }
    notifyListeners();
  }

  // --- People ---

  void addPerson(String name) {
    final colorIndex = _nextPersonId % Person.avatarColors.length;
    _people.add(Person(
      id: 'person_${_nextPersonId++}',
      name: name,
      avatarColor: Person.avatarColors[colorIndex],
    ));
    notifyListeners();
  }

  void removePerson(String personId) {
    _people.removeWhere((p) => p.id == personId);
    for (final set in _assignments.values) {
      set.remove(personId);
    }
    notifyListeners();
  }

  // --- Assignments ---

  void assignItemToPerson(String itemId, String personId) {
    _assignments.putIfAbsent(itemId, () => {});
    _assignments[itemId]!.add(personId);
    notifyListeners();
  }

  void unassignItemFromPerson(String itemId, String personId) {
    _assignments[itemId]?.remove(personId);
    if (_assignments[itemId]?.isEmpty ?? false) {
      _assignments.remove(itemId);
    }
    notifyListeners();
  }

  bool isItemAssignedToPerson(String itemId, String personId) {
    return _assignments[itemId]?.contains(personId) ?? false;
  }

  Set<String> getPeopleForItem(String itemId) {
    return _assignments[itemId] ?? {};
  }

  List<BillItem> getPersonItems(String personId) {
    return _items.where((item) {
      return _assignments[item.id]?.contains(personId) ?? false;
    }).toList();
  }

  List<BillItem> get unassignedItems {
    return _items.where((item) {
      final assigned = _assignments[item.id];
      return assigned == null || assigned.isEmpty;
    }).toList();
  }

  // --- Service Charge ---

  void setServiceChargePercent(double percent) {
    _serviceChargePercent = percent;
    notifyListeners();
  }

  void toggleServiceCharge(bool enabled) {
    _serviceChargeEnabled = enabled;
    notifyListeners();
  }

  // --- Calculations ---

  double getPersonSubtotal(String personId) {
    double sum = 0;
    for (final entry in _assignments.entries) {
      if (entry.value.contains(personId)) {
        final item = _items.firstWhere((i) => i.id == entry.key);
        sum += item.price / entry.value.length;
      }
    }
    return sum;
  }

  double getPersonTotal(String personId) {
    final sub = getPersonSubtotal(personId);
    if (_serviceChargeEnabled) {
      return sub + sub * _serviceChargePercent / 100;
    }
    return sub;
  }

  double getItemSplitPrice(String itemId, String personId) {
    final people = _assignments[itemId];
    if (people == null || !people.contains(personId)) return 0;
    final item = _items.firstWhere((i) => i.id == itemId);
    return item.price / people.length;
  }

  // --- Reset ---

  void reset({bool keepPeople = false}) {
    _items.clear();
    _assignments.clear();
    _serviceChargePercent = 15.0;
    _serviceChargeEnabled = true;
    _nextItemId = 0;
    if (!keepPeople) {
      _people.clear();
      _nextPersonId = 0;
    }
    notifyListeners();
  }
}
