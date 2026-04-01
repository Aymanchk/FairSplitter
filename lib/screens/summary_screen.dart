import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/share_helper.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final auth = context.read<AuthProvider>();
    final report = ShareHelper.generateReport(provider);

    // Save bill to backend if logged in
    _saveBillToBackend(provider, auth);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Итоги'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Success badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Счёт разделён',
                          style: TextStyle(
                            color: AppTheme.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Totals card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _summaryRow(
                          'Сумма чека:',
                          '${provider.subtotal.toStringAsFixed(0)} сом',
                        ),
                        if (provider.serviceChargeEnabled) ...[
                          const SizedBox(height: 8),
                          _summaryRow(
                            'Обслуживание (${provider.serviceChargePercent.toStringAsFixed(0)}%):',
                            '${provider.serviceChargeAmount.toStringAsFixed(0)} сом',
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Итого:',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${provider.total.toStringAsFixed(0)} сом',
                              style: const TextStyle(
                                color: AppTheme.green,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem(
                          '${provider.items.length}',
                          'Всего блюд',
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppTheme.border,
                        ),
                        _statItem(
                          '${provider.items.length - provider.unassignedItems.length}',
                          'Распределено',
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppTheme.border,
                        ),
                        _statItem(
                          '${_getSharedItemsCount(provider)}',
                          'Общих',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Person breakdown cards
                  ...provider.people.map((person) {
                    final items = provider.getPersonItems(person.id);
                    final total = provider.getPersonTotal(person.id);

                    return Container(
                      width: double.infinity,
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
                          // Person header
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: person.avatarColor,
                                child: Text(
                                  person.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${items.length} блюда',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(0)} сом',
                                style: TextStyle(
                                  color: person.avatarColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(color: AppTheme.border, height: 1),
                            const SizedBox(height: 12),
                            ...items.map((item) {
                              final splitPrice =
                                  provider.getItemSplitPrice(
                                      item.id, person.id);
                              final sharedWith =
                                  provider.getPeopleForItem(item.id);
                              final isShared = sharedWith.length > 1;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name +
                                            (isShared
                                                ? ' (1/${sharedWith.length})'
                                                : ''),
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${splitPrice.toStringAsFixed(0)} сом',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () =>
                          ShareHelper.shareViaTelegram(report),
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: const Text('Поделиться в Telegram'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                ShareHelper.shareViaWhatsApp(report),
                            icon: const Icon(Icons.chat_rounded, size: 18),
                            label: const Text('WhatsApp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side:
                                  const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                ShareHelper.shareViaSystem(report),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Ещё'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side:
                                  const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _getSharedItemsCount(BillProvider provider) {
    return provider.items.where((item) {
      final people = provider.getPeopleForItem(item.id);
      return people.length > 1;
    }).length;
  }

  void _saveBillToBackend(BillProvider provider, AuthProvider auth) {
    if (auth.isGuest || !auth.isLoggedIn) return;
    try {
      auth.api.saveBill(
        total: provider.total,
        serviceChargePercent: provider.serviceChargePercent,
        items: provider.items
            .map((i) => {'name': i.name, 'price': i.price})
            .toList(),
        people: provider.people
            .map((p) => {'name': p.name, 'id': p.id})
            .toList(),
        assignments: provider.assignments
            .map((k, v) => MapEntry(k, v.toList())),
      );
    } catch (_) {
      // Silent fail - bill is still shown locally
    }
  }
}
