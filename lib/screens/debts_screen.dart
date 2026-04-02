import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isGuest) {
        context.read<DebtProvider>().loadDebts();
        context.read<DebtProvider>().loadSummary();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final debtProvider = context.watch<DebtProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Text(
                'Долги',
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
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Войдите в аккаунт для отслеживания долгов',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Summary cards
              if (debtProvider.balances.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: debtProvider.balances.length,
                    itemBuilder: (context, index) {
                      final balance = debtProvider.balances[index];
                      final amount =
                          (balance['balance'] as num?)?.toDouble() ?? 0;
                      final name = balance['name']?.toString() ?? '';
                      final isPositive = amount > 0;

                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPositive
                                ? [
                                    AppTheme.green.withValues(alpha: 0.2),
                                    AppTheme.green.withValues(alpha: 0.05),
                                  ]
                                : [
                                    AppTheme.error.withValues(alpha: 0.2),
                                    AppTheme.error.withValues(alpha: 0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPositive
                                ? AppTheme.green.withValues(alpha: 0.3)
                                : AppTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isPositive
                                  ? 'Должен вам ${amount.abs().toStringAsFixed(0)} сом'
                                  : 'Вы должны ${amount.abs().toStringAsFixed(0)} сом',
                              style: TextStyle(
                                color: isPositive
                                    ? AppTheme.green
                                    : AppTheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Активные'),
                    Tab(text: 'Оплаченные'),
                  ],
                  onTap: (index) {
                    context.read<DebtProvider>().loadDebts(
                          show: index == 0 ? 'active' : 'paid',
                        );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Debt list
              Expanded(
                child: debtProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                    : debtProvider.debts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 48,
                                    color: AppTheme.green.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Нет долгов',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await debtProvider.loadDebts(
                                show: _tabController.index == 0
                                    ? 'active'
                                    : 'paid',
                              );
                              await debtProvider.loadSummary();
                            },
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: debtProvider.debts.length,
                              itemBuilder: (context, index) {
                                final debt = debtProvider.debts[index];
                                return _DebtCard(
                                  debt: debt,
                                  currentUserId: auth.userId,
                                  onMarkPaid: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final id = debt['id'] as int;
                                    await debtProvider.markPaid(id);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Долг отмечен как оплаченный')),
                                    );
                                  },
                                  onShowQR: () => _showQRDialog(debt),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQRDialog(Map<String, dynamic> debt) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final fromUser =
        Map<String, dynamic>.from(debt['from_user'] as Map? ?? {});
    final toUser =
        Map<String, dynamic>.from(debt['to_user'] as Map? ?? {});

    final qrData =
        'fairsplitter://pay?amount=${amount.toStringAsFixed(0)}&from=${fromUser['name']}&to=${toUser['name']}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR-код для оплаты',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${amount.toStringAsFixed(0)} сом',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${fromUser['name']} → ${toUser['name']}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Отсканируйте QR-код для перевода\nчерез Мбанк или О!Деньги',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Map<String, dynamic> debt;
  final int? currentUserId;
  final VoidCallback onMarkPaid;
  final VoidCallback onShowQR;

  const _DebtCard({
    required this.debt,
    required this.currentUserId,
    required this.onMarkPaid,
    required this.onShowQR,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final isPaid = debt['is_paid'] as bool? ?? false;
    final fromUser =
        Map<String, dynamic>.from(debt['from_user'] as Map? ?? {});
    final toUser =
        Map<String, dynamic>.from(debt['to_user'] as Map? ?? {});
    final description = debt['description']?.toString() ?? '';
    final isIOwe = fromUser['id'] == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? AppTheme.green.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isIOwe
                    ? AppTheme.error.withValues(alpha: 0.2)
                    : AppTheme.green.withValues(alpha: 0.2),
                child: Icon(
                  isIOwe
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: isIOwe ? AppTheme.error : AppTheme.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIOwe
                          ? 'Вы должны ${toUser['name']}'
                          : '${fromUser['name']} должен вам',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${amount.toStringAsFixed(0)} сом',
                style: TextStyle(
                  color: isIOwe ? AppTheme.error : AppTheme.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: onShowQR,
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('QR-код', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.border),
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
                    height: 38,
                    child: FilledButton.icon(
                      onPressed: onMarkPaid,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Оплачено',
                          style: TextStyle(fontSize: 13)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Оплачено',
                style: TextStyle(
                  color: AppTheme.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
