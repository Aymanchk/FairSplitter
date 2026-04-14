import 'package:flutter/foundation.dart';
import '../models/bill_item.dart';
import '../models/person.dart';
import '../models/expense_category.dart';

enum SplitMode { byItems, equal, percentage, shares }

enum Currency { kgs, usd, eur, rub, kzt }

extension CurrencyExt on Currency {
  String get symbol {
    switch (this) {
      case Currency.kgs: return 'сом';
      case Currency.usd: return '\$';
      case Currency.eur: return '€';
      case Currency.rub: return '₽';
      case Currency.kzt: return '₸';
    }
  }

  String get code {
    switch (this) {
      case Currency.kgs: return 'KGS';
      case Currency.usd: return 'USD';
      case Currency.eur: return 'EUR';
      case Currency.rub: return 'RUB';
      case Currency.kzt: return 'KZT';
    }
  }
}

class BillProvider extends ChangeNotifier {
  final List<BillItem> _items = [];
  final List<Person> _people = [];
  double _serviceChargePercent = 0.0;
  bool _serviceChargeEnabled = false;
  final Map<String, Set<String>> _assignments = {};
  int _nextItemId = 0;
  int _nextPersonId = 0;
  ExpenseCategory _category = ExpenseCategory.all.last; // default: Прочее
  SplitMode _splitMode = SplitMode.byItems;
  Currency _currency = Currency.kgs;
  String _billTitle = '';

  // Percentage/shares maps: personId -> value
  final Map<String, double> _percentages = {};
  final Map<String, int> _shares = {};

  List<BillItem> get items => List.unmodifiable(_items);
  List<Person> get people => List.unmodifiable(_people);
  double get serviceChargePercent => _serviceChargePercent;
  bool get serviceChargeEnabled => _serviceChargeEnabled;
  Map<String, Set<String>> get assignments =>
      _assignments.map((k, v) => MapEntry(k, Set.unmodifiable(v)));
  ExpenseCategory get category => _category;
  SplitMode get splitMode => _splitMode;
  Currency get currency => _currency;
  String get billTitle => _billTitle;
  Map<String, double> get percentages => Map.unmodifiable(_percentages);
  Map<String, int> get shares => Map.unmodifiable(_shares);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.price);

  double get serviceChargeAmount =>
      _serviceChargeEnabled ? subtotal * _serviceChargePercent / 100 : 0;

  double get total => subtotal + serviceChargeAmount;

  int get totalShares => _shares.values.fold(0, (sum, s) => sum + s);

  // --- Category ---

  void setCategory(ExpenseCategory cat) {
    _category = cat;
    // Apply default service charge for category
    if (cat.defaultServicePercent > 0) {
      _serviceChargeEnabled = true;
      _serviceChargePercent = cat.defaultServicePercent;
    } else {
      _serviceChargeEnabled = false;
      _serviceChargePercent = 0.0;
    }
    notifyListeners();
  }

  // --- Split Mode ---

  void setSplitMode(SplitMode mode) {
    _splitMode = mode;
    notifyListeners();
  }

  // --- Currency ---

  void setCurrency(Currency c) {
    _currency = c;
    notifyListeners();
  }

  // --- Title ---

  void setBillTitle(String title) {
    _billTitle = title;
    notifyListeners();
  }

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

  void addPerson(String name, {int? userId, String? avatarUrl}) {
    final colorIndex = _nextPersonId % Person.avatarColors.length;
    _people.add(Person(
      id: 'person_${_nextPersonId++}',
      name: name,
      avatarColor: Person.avatarColors[colorIndex],
      userId: userId,
      avatarUrl: avatarUrl,
    ));
    notifyListeners();
  }

  void removePerson(String personId) {
    _people.removeWhere((p) => p.id == personId);
    for (final set in _assignments.values) {
      set.remove(personId);
    }
    _percentages.remove(personId);
    _shares.remove(personId);
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

  // --- Percentages ---

  void setPersonPercentage(String personId, double pct) {
    _percentages[personId] = pct;
    notifyListeners();
  }

  // --- Shares ---

  void setPersonShares(String personId, int count) {
    _shares[personId] = count;
    notifyListeners();
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
    switch (_splitMode) {
      case SplitMode.equal:
        if (_people.isEmpty) return 0;
        return subtotal / _people.length;

      case SplitMode.percentage:
        final pct = _percentages[personId] ?? 0;
        return subtotal * pct / 100;

      case SplitMode.shares:
        final personShares = _shares[personId] ?? 1;
        final total = totalShares;
        if (total == 0) return 0;
        return subtotal * personShares / total;

      case SplitMode.byItems:
        double sum = 0;
        for (final entry in _assignments.entries) {
          if (entry.value.contains(personId)) {
            final item = _items.firstWhere((i) => i.id == entry.key);
            sum += item.price / entry.value.length;
          }
        }
        return sum;
    }
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
    _nextItemId = 0;
    _splitMode = SplitMode.byItems;
    _percentages.clear();
    _shares.clear();
    if (!keepPeople) {
      _people.clear();
      _nextPersonId = 0;
      _billTitle = '';
      _serviceChargePercent = 0.0;
      _serviceChargeEnabled = false;
      _category = ExpenseCategory.all.last;
      _currency = Currency.kgs;
    } else {
      // Re-apply category default service charge
      if (_category.defaultServicePercent > 0) {
        _serviceChargeEnabled = true;
        _serviceChargePercent = _category.defaultServicePercent;
      } else {
        _serviceChargeEnabled = false;
        _serviceChargePercent = 0.0;
      }
    }
    notifyListeners();
  }
}
