import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;
  String _filter = 'all'; // all | month | done

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final result = await auth.api.getUserBills();
      final raw = result['results'] ?? result['bills'] ?? [];
      if (mounted) {
        setState(() {
          _bills = List<Map<String, dynamic>>.from(raw is List ? raw : []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBill(String id, int index) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.api.deleteBill(id);
    if (success && mounted) {
      setState(() => _bills.removeAt(index));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Счёт удалён')));
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'month') {
      final now = DateTime.now();
      return _bills.where((b) {
        try {
          final d = DateTime.parse(b['created_at'].toString());
          return d.month == now.month && d.year == now.year;
        } catch (_) {
          return false;
        }
      }).toList();
    }
    return _bills;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _Blob(color: const Color(0xFFF5A623), size: 180),
            ),
            Positioned(
              bottom: 120,
              left: -30,
              child: _Blob(color: const Color(0xFFFFD166), size: 120),
            ),
            Positioned(
              top: 200,
              left: -50,
              child: _Blob(color: const Color(0xFFFF8F5E), size: 100),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text(
                      'История',
                      style: AppTheme.headingStyle(fontSize: 28),
                    ),
                  ),

                  // ── Filter chips ─────────────────────────────────────
                  if (!auth.isGuest) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _FilterChip(
                            label: 'Все',
                            active: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Этот месяц',
                            active: _filter == 'month',
                            onTap: () => setState(() => _filter = 'month'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Expanded(
                    child: auth.isGuest
                        ? _GuestPlaceholder()
                        : _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.primary),
                              )
                            : _filtered.isEmpty
                                ? _EmptyState()
                                : RefreshIndicator(
                                    onRefresh: _loadBills,
                                    color: AppTheme.primary,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: _filtered.length,
                                      itemBuilder: (_, i) {
                                        final bill = _filtered[i];
                                        final originalIndex =
                                            _bills.indexOf(bill);
                                        return _BillCard(
                                          bill: bill,
                                          onTap: () =>
                                              _showBillDetail(bill),
                                          onDelete: () => _deleteBill(
                                            bill['id'].toString(),
                                            originalIndex,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBillDetail(Map<String, dynamic> bill) {
    final items =
        List<Map<String, dynamic>>.from(bill['items'] ?? []);
    final people =
        List<Map<String, dynamic>>.from(bill['people'] ?? []);
    final assignments =
        Map<String, dynamic>.from(bill['assignments'] ?? {});
    final total = (bill['total'] as num?)?.toDouble() ?? 0;
    final servicePercent =
        (bill['service_charge_percent'] as num?)?.toDouble() ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                bill['title']?.toString().isNotEmpty == true
                    ? bill['title']
                    : 'Счёт #${bill['id']}',
                style: AppTheme.headingStyle(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(bill['created_at']?.toString()),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Total
              LiquidGlass(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15)),
                    Text(
                      '${total.toStringAsFixed(0)} сом',
                      style: AppTheme.moneyStyle(fontSize: 22),
                    ),
                  ],
                ),
              ),
              if (servicePercent > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Обслуживание: ${servicePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),

              // Items
              const Text('Позиции',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['name']?.toString() ?? '',
                            style: const TextStyle(
                                color: AppTheme.textSecondary)),
                        Text(
                          '${(item['price'] as num?)?.toStringAsFixed(0) ?? '0'} сом',
                          style: const TextStyle(
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),

              // People
              const Text('Участники',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: people.map((p) {
                  double personTotal = 0;
                  final personId = p['id']?.toString() ?? '';
                  for (final entry in assignments.entries) {
                    final assigned = List<String>.from(
                        entry.value as List? ?? []);
                    if (assigned.contains(personId)) {
                      final item = items.firstWhere(
                        (i) =>
                            i['id']?.toString() == entry.key ||
                            items.indexOf(i).toString() == entry.key,
                        orElse: () => {},
                      );
                      if (item.isNotEmpty) {
                        personTotal +=
                            ((item['price'] as num?)?.toDouble() ?? 0) /
                                assigned.length;
                      }
                    }
                  }
                  if (servicePercent > 0) {
                    personTotal += personTotal * servicePercent / 100;
                  }
                  return LiquidGlass(
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Column(
                      children: [
                        Text(p['name']?.toString() ?? '',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '${personTotal.toStringAsFixed(0)} сом',
                          style: AppTheme.moneyStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? s) {
    if (s == null) return '';
    try {
      return DateFormat('d MMMM yyyy, HH:mm', 'ru').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF1A1A1A) : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _BillCard(
      {required this.bill, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final total = (bill['total'] as num?)?.toDouble() ?? 0;
    final people = List.from(bill['people'] ?? []);
    final items = List.from(bill['items'] ?? []);
    final title = bill['title']?.toString();
    final createdAt = bill['created_at']?.toString();

    String dateStr = '';
    if (createdAt != null) {
      try {
        final d = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(d);
        if (diff.inDays == 0) {
          dateStr = 'Сегодня';
        } else if (diff.inDays == 1) {
          dateStr = 'Вчера';
        } else if (diff.inDays < 7) {
          dateStr = '${diff.inDays} дн. назад';
        } else {
          dateStr = DateFormat('d MMM').format(d);
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(
              color: AppTheme.primary,
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title?.isNotEmpty == true
                              ? title!
                              : 'Счёт #${bill['id']}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(dateStr,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} сом',
                    style: AppTheme.moneyStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded,
                      size: 13,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text('${items.length} позиций',
                      style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(Icons.people_rounded,
                      size: 13,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text('${people.length} чел.',
                      style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить счёт?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Отмена')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onDelete();
                            },
                            child: const Text('Удалить',
                                style: TextStyle(color: AppTheme.danger)),
                          ),
                        ],
                      ),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F37D}\u{FE0F}', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text('Счетов пока нет',
              style: AppTheme.headingStyle(fontSize: 17)),
          const SizedBox(height: 6),
          const Text('Разделите первый счёт,\nи он появится здесь',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _GuestPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F512}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              'Войдите в аккаунт',
              style: AppTheme.headingStyle(fontSize: 17),
            ),
            const SizedBox(height: 6),
            const Text(
              'История счетов сохраняется\nтолько для зарегистрированных',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
    );
  }
}
