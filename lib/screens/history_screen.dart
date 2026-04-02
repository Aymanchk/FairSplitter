import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;

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
      final results = result['results'] ?? result['bills'] ?? [];
      setState(() {
        _bills = List<Map<String, dynamic>>.from(
            results is List ? results : []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBill(String id, int index) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.api.deleteBill(id);
    if (success && mounted) {
      setState(() => _bills.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Счёт удалён')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                'История',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (auth.isGuest)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Войдите в аккаунт, чтобы видеть историю счетов',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_bills.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'Пока нет счетов',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Разделите первый счёт, и он появится здесь',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadBills,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _bills.length,
                    itemBuilder: (context, index) {
                      final bill = _bills[index];
                      return _BillCard(
                        bill: bill,
                        onDelete: () => _deleteBill(
                          bill['id'].toString(),
                          index,
                        ),
                        onTap: () => _showBillDetails(bill),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    final items = List<Map<String, dynamic>>.from(bill['items'] ?? []);
    final people = List<Map<String, dynamic>>.from(bill['people'] ?? []);
    final assignments =
        Map<String, dynamic>.from(bill['assignments'] ?? {});
    final total = (bill['total'] as num?)?.toDouble() ?? 0;
    final servicePercent =
        (bill['service_charge_percent'] as num?)?.toDouble() ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                bill['title']?.toString().isNotEmpty == true
                    ? bill['title']
                    : 'Счёт #${bill['id']}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(bill['created_at']?.toString()),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        )),
                    Text(
                      '${total.toStringAsFixed(0)} сом',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (servicePercent > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Обслуживание: ${servicePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Items
              const Text('Позиции',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
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
                          style:
                              const TextStyle(color: AppTheme.textPrimary),
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
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: people.map((p) {
                  // Calculate person total
                  double personTotal = 0;
                  final personId = p['id']?.toString() ?? '';
                  for (final entry in assignments.entries) {
                    final assignedPeople =
                        List<String>.from(entry.value as List? ?? []);
                    if (assignedPeople.contains(personId)) {
                      final item = items.firstWhere(
                        (i) => i['id']?.toString() == entry.key ||
                            items.indexOf(i).toString() == entry.key,
                        orElse: () => {},
                      );
                      if (item.isNotEmpty) {
                        final price =
                            (item['price'] as num?)?.toDouble() ?? 0;
                        personTotal += price / assignedPeople.length;
                      }
                    }
                  }
                  if (servicePercent > 0) {
                    personTotal += personTotal * servicePercent / 100;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Text(p['name']?.toString() ?? '',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                          '${personTotal.toStringAsFixed(0)} сом',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 13,
                          ),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy, HH:mm', 'ru').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _BillCard({
    required this.bill,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = (bill['total'] as num?)?.toDouble() ?? 0;
    final people = List.from(bill['people'] ?? []);
    final items = List.from(bill['items'] ?? []);
    final createdAt = bill['created_at']?.toString();
    final title = bill['title']?.toString();

    String dateStr = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final diff = now.difference(date);
        if (diff.inMinutes < 60) {
          dateStr = '${diff.inMinutes} мин назад';
        } else if (diff.inHours < 24) {
          dateStr = '${diff.inHours} ч назад';
        } else if (diff.inDays < 7) {
          dateStr = '${diff.inDays} дн назад';
        } else {
          dateStr = DateFormat('d MMM yyyy').format(date);
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} сом',
                  style: const TextStyle(
                    color: AppTheme.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.restaurant_menu,
                    size: 14, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  '${items.length} позиций',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people_outline,
                    size: 14, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  '${people.length} чел',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить счёт?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onDelete();
                            },
                            child: const Text('Удалить',
                                style: TextStyle(color: AppTheme.error)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
