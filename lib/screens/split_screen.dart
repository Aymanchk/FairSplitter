import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../utils/ocr_helper.dart';
import 'summary_screen.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить блюдо'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Название блюда'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(hintText: 'Цена (сом)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price =
                  double.tryParse(priceCtrl.text.replaceAll(',', '.'));
              if (name.isNotEmpty && price != null && price > 0) {
                context.read<BillProvider>().addItem(name, price);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Сканировать чек',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _ScanOption(
                icon: Icons.camera_alt_rounded,
                color: AppTheme.primary,
                title: 'Камера',
                subtitle: 'Сфотографировать чек',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              _ScanOption(
                icon: Icons.photo_library_rounded,
                color: const Color(0xFFFF8F5E),
                title: 'Галерея',
                subtitle: 'Выбрать фото чека',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return;
    try {
      final items = await OcrHelper.scanReceipt(source: source);
      if (items.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Не удалось распознать. Попробуйте при хорошем освещении.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        context.read<BillProvider>().addItemsFromOcr(items);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Добавлено ${items.length} позиций')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: _Blob(color: const Color(0xFFF5A623), size: 160),
            ),
            SafeArea(
              child: Consumer<BillProvider>(
                builder: (context, provider, _) {
                  final unassignedTotal = provider.unassignedItems
                      .fold<double>(0, (s, i) => s + i.price);

                  return Column(
                    children: [
                      // ── AppBar ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: LiquidGlass(
                                borderRadius: BorderRadius.circular(12),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: AppTheme.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Разделить счёт',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Floating total pill ──────────────────────────
                      Center(
                        child: LiquidGlass(
                          borderRadius: BorderRadius.circular(50),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Column(
                            children: [
                              Text(
                                '${provider.total.toStringAsFixed(0)} сом',
                                style: AppTheme.moneyStyle(fontSize: 22),
                              ),
                              if (provider.serviceChargeEnabled)
                                Text(
                                  'включая ${provider.serviceChargePercent.toStringAsFixed(0)}% обслуживания',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Service charge ─────────────────────
                              _buildServiceCharge(provider),
                              const SizedBox(height: 16),

                              // ── Action buttons ─────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.add_rounded,
                                      label: 'Добавить',
                                      color: AppTheme.primary,
                                      onTap: _showAddItemDialog,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.camera_alt_rounded,
                                      label: 'Скан чека',
                                      color: const Color(0xFFFF8F5E),
                                      onTap: _scanReceipt,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ── Items list ─────────────────────────
                              Row(
                                children: [
                                  Text(
                                    'Блюда (${provider.items.length})',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (provider.unassignedItems.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${provider.unassignedItems.length} не распределено',
                                        style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              if (provider.items.isEmpty)
                                _EmptyItemsState()
                              else
                                ...provider.items.map((item) {
                                  final assigned =
                                      provider.getPeopleForItem(item.id);
                                  return _ItemTile(
                                    item: item,
                                    assignedPeople: assigned,
                                    provider: provider,
                                  );
                                }),

                              const SizedBox(height: 20),

                              // ── Drop targets ───────────────────────
                              if (provider.people.isNotEmpty) ...[
                                const Text(
                                  'Перетащите блюда на участников',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _PeopleDropRow(provider: provider),
                              ],

                              if (unassignedTotal > 0) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: LiquidGlass(
                                    borderRadius: BorderRadius.circular(50),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Text(
                                      'Осталось: ${unassignedTotal.toStringAsFixed(0)} сом',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom button ────────────────────────────────
                      _BottomBar(
                        enabled: provider.items.isNotEmpty &&
                            provider.unassignedItems.isEmpty,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SummaryScreen()),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCharge(BillProvider provider) {
    const percentages = [0.0, 10.0, 15.0];
    return LiquidGlass(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.receipt_rounded,
              size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          const Text(
            'Обслуживание',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ...percentages.map((pct) {
            final isZero = pct == 0;
            final isActive = isZero
                ? !provider.serviceChargeEnabled
                : (provider.serviceChargeEnabled &&
                    provider.serviceChargePercent == pct);
            return GestureDetector(
              onTap: () {
                if (isZero) {
                  provider.toggleServiceCharge(false);
                  provider.setServiceChargePercent(0);
                } else {
                  provider.toggleServiceCharge(true);
                  provider.setServiceChargePercent(pct);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF1A1A1A)
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final BillItem item;
  final Set<String> assignedPeople;
  final BillProvider provider;

  const _ItemTile({
    required this.item,
    required this.assignedPeople,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isAssigned = assignedPeople.isNotEmpty;
    return Draggable<BillItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '${item.name}  ${item.price.toStringAsFixed(0)} сом',
            style: const TextStyle(
                color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
          ),
        ),
      ),
      childWhenDragging:
          Opacity(opacity: 0.3, child: _card(context, isAssigned)),
      child: _card(context, isAssigned),
    );
  }

  Widget _card(BuildContext context, bool isAssigned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isAssigned
            ? AppTheme.primary.withValues(alpha: 0.10)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAssigned
              ? AppTheme.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Mini assigned avatars
          if (assignedPeople.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: assignedPeople.take(3).map((pid) {
                final person =
                    provider.people.firstWhere((p) => p.id == pid);
                return Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: person.avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.background, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      person.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          // Split badge
          if (assignedPeople.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '÷${assignedPeople.length}',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            '${item.price.toStringAsFixed(0)} сом',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.removeItem(item.id),
            child: Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleDropRow extends StatelessWidget {
  final BillProvider provider;
  const _PeopleDropRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: provider.people.map((person) {
          final personTotal = provider.getPersonTotal(person.id);
          return DragTarget<BillItem>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              final item = details.data;
              if (provider.isItemAssignedToPerson(item.id, person.id)) {
                provider.unassignItemFromPerson(item.id, person.id);
              } else {
                provider.assignItemToPerson(item.id, person.id);
              }
            },
            builder: (context, candidates, _) {
              final hovering = candidates.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: hovering ? 64 : 56,
                      height: hovering ? 64 : 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hovering
                            ? person.avatarColor
                            : person.avatarColor.withValues(alpha: 0.75),
                        border: Border.all(
                          color: hovering
                              ? const Color(0xFFFFD166)
                              : person.avatarColor,
                          width: hovering ? 3 : 2,
                        ),
                        boxShadow: hovering
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF5A623)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          person.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 12),
                    ),
                    if (personTotal > 0)
                      Text(
                        '${personTotal.toStringAsFixed(0)} с',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: BorderRadius.circular(14),
      interactive: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _BottomBar({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: enabled
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Итоги',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A))),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            size: 20, color: Color(0xFF1A1A1A)),
                      ],
                    ),
                  ),
                )
              : FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Итоги',
                          style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          size: 20, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ScanOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title:
          Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12)),
      onTap: onTap,
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: const Column(
        children: [
          Text('🍽️', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text(
            'Пока тут пусто. Время ужинать?\nДобавьте блюда или сканируйте чек',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
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
        color: color.withValues(alpha: 0.20),
      ),
    );
  }
}
