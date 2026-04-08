import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/debt_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import 'add_people_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentBills = [];
  bool _loadingBills = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      setState(() => _loadingBills = false);
      return;
    }
    try {
      context.read<DebtProvider>().loadSummary();
      final result = await auth.api.getUserBills();
      final raw = result['results'] ?? result['bills'] ?? [];
      if (mounted) {
        setState(() {
          _recentBills =
              List<Map<String, dynamic>>.from(raw is List ? raw : [])
                  .take(5)
                  .toList();
          _loadingBills = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBills = false);
    }
  }

  void _openNewBill() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPeopleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final debtProvider = context.watch<DebtProvider>();
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final userName = auth.userName?.split(' ').first ?? 'там';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient blobs
          Positioned(
            top: -60,
            right: -40,
            child: _Blob(color: AppTheme.primary, size: 200),
          ),
          Positioned(
            top: 140,
            left: -50,
            child: _Blob(color: AppTheme.accent, size: 160),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting, $userName 👋',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('d MMMM, EEEE', 'ru')
                                          .format(now),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // ── Quick Actions ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _QuickActionPill(
                            icon: Icons.add_rounded,
                            label: 'Новый счёт',
                            onTap: _openNewBill,
                          ),
                          const SizedBox(width: 10),
                          _QuickActionPill(
                            icon: Icons.camera_alt_rounded,
                            label: 'Скан чека',
                            onTap: _openNewBill,
                          ),
                          const SizedBox(width: 10),
                          _QuickActionPill(
                            icon: Icons.group_add_rounded,
                            label: 'Создать группу',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Balance summary ────────────────────────────────────
                  if (!auth.isGuest &&
                      debtProvider.balances.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Баланс',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          itemCount:
                              debtProvider.balances.length.clamp(0, 4),
                          itemBuilder: (_, i) {
                            final b = debtProvider.balances[i];
                            final amount =
                                (b['balance'] as num?)?.toDouble() ?? 0;
                            final name = b['name']?.toString() ?? '';
                            final isPos = amount > 0;
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              child: LiquidGlass(
                                borderRadius: BorderRadius.circular(16),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isPos
                                          ? '+${amount.abs().toStringAsFixed(0)} сом'
                                          : '-${amount.abs().toStringAsFixed(0)} сом',
                                      style: TextStyle(
                                        color: isPos
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // ── Recent Bills ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Text(
                            'Недавние счета',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          if (_recentBills.isNotEmpty)
                            Text(
                              'Все',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  if (auth.isGuest)
                    SliverToBoxAdapter(
                      child: _GuestBillsPlaceholder(
                          onCreateBill: _openNewBill),
                    )
                  else if (_loadingBills)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary),
                        ),
                      ),
                    )
                  else if (_recentBills.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyBillsState(onCreateBill: _openNewBill),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) =>
                              _BillCard(bill: _recentBills[i]),
                          childCount: _recentBills.length,
                        ),
                      ),
                    ),

                  // Bottom padding for FAB + nav bar
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 120)),
                ],
              ),
            ),
          ),

          // ── FAB ─────────────────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 90,
            child: _GradientFAB(onTap: _openNewBill),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _QuickActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionPill(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: BorderRadius.circular(50),
      interactive: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.accent),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final total = (bill['total'] as num?)?.toDouble() ?? 0;
    final people = List.from(bill['people'] ?? []);
    final createdAt = bill['created_at']?.toString();
    final title = bill['title']?.toString();

    String dateStr = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(date);
        if (diff.inDays == 0) {
          dateStr = 'Сегодня';
        } else if (diff.inDays == 1) {
          dateStr = 'Вчера';
        } else if (diff.inDays < 7) {
          dateStr = '${diff.inDays} дн. назад';
        } else {
          dateStr = DateFormat('d MMM').format(date);
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTheme.primary, width: 3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (people.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Text('·',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(
                          '${people.length} чел.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${total.toStringAsFixed(0)} сом',
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

class _EmptyBillsState extends StatelessWidget {
  final VoidCallback onCreateBill;
  const _EmptyBillsState({required this.onCreateBill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: LiquidGlass(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            const Text('😴', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Счетов пока нет',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Разделите первый счёт,\nи он появится здесь',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: onCreateBill,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Создать счёт'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBillsPlaceholder extends StatelessWidget {
  final VoidCallback onCreateBill;
  const _GuestBillsPlaceholder({required this.onCreateBill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: LiquidGlass(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('🧾', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Войдите, чтобы сохранять историю',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Счета гостей не сохраняются',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onCreateBill,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Создать'),
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
        color: color.withValues(alpha: 0.22),
      ),
    );
  }
}
