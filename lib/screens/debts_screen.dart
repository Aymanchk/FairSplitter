import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

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
    final dp = context.watch<DebtProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -40,
            child: _Blob(color: AppTheme.danger, size: 180),
          ),
          Positioned(
            bottom: 80,
            right: -30,
            child: _Blob(color: AppTheme.success, size: 140),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    'Долги',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                if (auth.isGuest)
                  Expanded(child: _GuestPlaceholder())
                else ...[
                  // ── Balance summary scroll ─────────────────────────
                  if (dp.balances.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 88,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: dp.balances.length,
                        itemBuilder: (_, i) {
                          final b = dp.balances[i];
                          final amount =
                              (b['balance'] as num?)?.toDouble() ?? 0;
                          final name = b['name']?.toString() ?? '';
                          final isPos = amount > 0;
                          return Container(
                            width: 170,
                            margin: const EdgeInsets.only(right: 12),
                            child: LiquidGlass(
                              borderRadius: BorderRadius.circular(16),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    isPos
                                        ? '+ ${amount.abs().toStringAsFixed(0)} сом'
                                        : '− ${amount.abs().toStringAsFixed(0)} сом',
                                    style: TextStyle(
                                      color: isPos
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    isPos ? 'должен вам' : 'вы должны',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Tab switcher ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LiquidGlass(
                      borderRadius: BorderRadius.circular(14),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textSecondary,
                        dividerHeight: 0,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Активные'),
                          Tab(text: 'Оплаченные'),
                        ],
                        onTap: (i) {
                          context.read<DebtProvider>().loadDebts(
                                show: i == 0 ? 'active' : 'paid',
                              );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: dp.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary))
                        : dp.debts.isEmpty
                            ? _EmptyDebts()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await dp.loadDebts(
                                    show: _tabController.index == 0
                                        ? 'active'
                                        : 'paid',
                                  );
                                  await dp.loadSummary();
                                },
                                color: AppTheme.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: dp.debts.length,
                                  itemBuilder: (_, i) => _DebtCard(
                                    debt: dp.debts[i],
                                    currentUserId: auth.userId,
                                    onMarkPaid: () async {
                                      await dp.markPaid(
                                          dp.debts[i]['id'] as int);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text('Долг отмечен оплаченным'),
                                        ));
                                      }
                                    },
                                    onShowQR: () =>
                                        _showQRModal(dp.debts[i]),
                                  ),
                                ),
                              ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRModal(Map<String, dynamic> debt) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final from = Map<String, dynamic>.from(debt['from_user'] as Map? ?? {});
    final to = Map<String, dynamic>.from(debt['to_user'] as Map? ?? {});
    final qrData =
        'fairsplitter://pay?amount=${amount.toStringAsFixed(0)}&from=${from['name']}&to=${to['name']}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('QR для оплаты',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${amount.toStringAsFixed(0)} сом',
              style: const TextStyle(
                  color: AppTheme.success,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '${from['name']} → ${to['name']}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 20),
                ],
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
              'Отсканируйте для перевода через Мбанк или О!Деньги',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

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
    final from = Map<String, dynamic>.from(debt['from_user'] as Map? ?? {});
    final to = Map<String, dynamic>.from(debt['to_user'] as Map? ?? {});
    final description = debt['description']?.toString() ?? '';
    final isIOwe = from['id'] == currentUserId;

    return Dismissible(
      key: Key(debt['id'].toString()),
      direction: isPaid ? DismissDirection.none : DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Оплачено',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onMarkPaid();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPaid
                ? AppTheme.success.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: (isIOwe ? AppTheme.danger : AppTheme.success)
                  .withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isIOwe ? AppTheme.danger : AppTheme.success)
                          .withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      isIOwe
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color:
                          isIOwe ? AppTheme.danger : AppTheme.success,
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
                              ? 'Вы должны ${to['name']}'
                              : '${from['name']} должен вам',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (description.isNotEmpty)
                          Text(description,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(0)} сом',
                    style: TextStyle(
                      color: isIOwe ? AppTheme.danger : AppTheme.success,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isPaid) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✓ Оплачено',
                      style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: LiquidGlass(
                          borderRadius: BorderRadius.circular(10),
                          interactive: true,
                          onTap: onShowQR,
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.qr_code_rounded,
                                  size: 15, color: AppTheme.accent),
                              SizedBox(width: 6),
                              Text('QR-код',
                                  style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: FilledButton.icon(
                          onPressed: onMarkPaid,
                          icon: const Icon(Icons.check_rounded, size: 15),
                          label: const Text('Оплачено',
                              style: TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDebts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('💰', style: TextStyle(fontSize: 52)),
          SizedBox(height: 14),
          Text('Долгов нет',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Все долги урегулированы',
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
          children: const [
            Text('🔐', style: TextStyle(fontSize: 48)),
            SizedBox(height: 14),
            Text('Войдите в аккаунт',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Для отслеживания долгов\nнужна регистрация',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
        color: color.withValues(alpha: 0.15),
      ),
    );
  }
}
