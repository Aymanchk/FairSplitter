import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../utils/share_helper.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _totalCountController;
  late Animation<double> _totalCountAnim;
  bool _saved = false;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    final provider = context.read<BillProvider>();
    _totalCountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _totalCountAnim = Tween<double>(begin: 0, end: provider.total).animate(
      CurvedAnimation(parent: _totalCountController, curve: Curves.easeOut),
    );
    _totalCountController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trySaveBill();
    });
  }

  void _trySaveBill() {
    if (_saved) return;
    _saved = true;
    final provider = context.read<BillProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.isGuest || !auth.isLoggedIn) return;
    try {
      auth.api.saveBill(
        total: provider.total,
        serviceChargePercent: provider.serviceChargePercent,
        items: provider.items.map((i) => {'name': i.name, 'price': i.price}).toList(),
        people: provider.people.map((p) => {'name': p.name, 'id': p.id}).toList(),
        assignments: provider.assignments.map((k, v) => MapEntry(k, v.toList())),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _totalCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final report = ShareHelper.generateReport(provider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient blobs
          Positioned(
            top: -60,
            left: -40,
            child: _Blob(color: AppTheme.primary, size: 220),
          ),
          Positioned(
            bottom: 80,
            right: -50,
            child: _Blob(color: AppTheme.success, size: 160),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: LiquidGlass(
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Итоги',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Success + confetti badge ────────────────
                        FadeTransition(
                          opacity: _confettiController,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.4),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _confettiController,
                              curve: Curves.easeOutBack,
                            )),
                            child: LiquidGlass(
                              borderRadius: BorderRadius.circular(50),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('🎉',
                                      style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Счёт разделён!',
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_rounded,
                                      color: AppTheme.success, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Animated total pill ─────────────────────
                        AnimatedBuilder(
                          animation: _totalCountAnim,
                          builder: (_, __) => LiquidGlass(
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            child: Column(
                              children: [
                                Text(
                                  '${_totalCountAnim.value.toStringAsFixed(0)} сом',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -1,
                                  ),
                                ),
                                if (provider.serviceChargeEnabled) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'включая ${provider.serviceChargePercent.toStringAsFixed(0)}% обслуживания '
                                    '(${provider.serviceChargeAmount.toStringAsFixed(0)} сом)',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Stats row ──────────────────────────────
                        LiquidGlass(
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatChip(
                                value: '${provider.items.length}',
                                label: 'Блюд',
                              ),
                              Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.white
                                      .withValues(alpha: 0.08)),
                              _StatChip(
                                value: '${provider.people.length}',
                                label: 'Человек',
                              ),
                              Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.white
                                      .withValues(alpha: 0.08)),
                              _StatChip(
                                value: '${_sharedCount(provider)}',
                                label: 'Общих',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Per-person breakdown ────────────────────
                        ...provider.people.map((person) {
                          final items = provider.getPersonItems(person.id);
                          final total = provider.getPersonTotal(person.id);
                          return _PersonCard(
                            person: person,
                            items: items,
                            total: total,
                            provider: provider,
                          );
                        }),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Bottom share bar ───────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: FilledButton.icon(
                              onPressed: () =>
                                  ShareHelper.shareViaTelegram(report),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Telegram'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                                child: LiquidGlass(
                                  borderRadius: BorderRadius.circular(12),
                                  interactive: true,
                                  onTap: () =>
                                      ShareHelper.shareViaWhatsApp(report),
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.chat_rounded,
                                          size: 16,
                                          color: AppTheme.textSecondary),
                                      SizedBox(width: 6),
                                      Text('WhatsApp',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: LiquidGlass(
                                  borderRadius: BorderRadius.circular(12),
                                  interactive: true,
                                  onTap: () =>
                                      ShareHelper.shareViaSystem(report),
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.share_rounded,
                                          size: 16,
                                          color: AppTheme.textSecondary),
                                      SizedBox(width: 6),
                                      Text('Ещё',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _sharedCount(BillProvider p) =>
      p.items.where((i) => p.getPeopleForItem(i.id).length > 1).length;
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  final dynamic person;
  final List<dynamic> items;
  final double total;
  final BillProvider provider;

  const _PersonCard({
    required this.person,
    required this.items,
    required this.total,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${items.length} позиц.',
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
                  style: TextStyle(
                    color: person.avatarColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Mini progress bar
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: provider.total > 0 ? (total / provider.total) : 0,
                backgroundColor: AppTheme.surfaceLight,
                valueColor:
                    AlwaysStoppedAnimation<Color>(person.avatarColor),
                minHeight: 4,
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...items.map((item) {
                final splitPrice =
                    provider.getItemSplitPrice(item.id, person.id);
                final sharedWith = provider.getPeopleForItem(item.id);
                final isShared = sharedWith.length > 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name +
                              (isShared ? ' (÷${sharedWith.length})' : ''),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${splitPrice.toStringAsFixed(0)} сом',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
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
            fontSize: 11,
          ),
        ),
      ],
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
        color: color.withValues(alpha: 0.20),
      ),
    );
  }
}
