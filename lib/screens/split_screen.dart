import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/ocr_helper.dart';
import 'summary_screen.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final bool _showAddForm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.replaceAll(',', '.');
    final price = double.tryParse(priceText);
    if (name.isEmpty || price == null || price <= 0) return;

    context.read<BillProvider>().addItem(name, price);
    _nameController.clear();
    _priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Разделить счёт'),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, provider, _) {
          final unassignedTotal = provider.unassignedItems.fold<double>(
            0,
            (sum, item) => sum + item.price,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service charge section
                      _buildServiceCharge(provider),
                      const SizedBox(height: 16),

                      // Totals
                      _buildTotals(provider),
                      const SizedBox(height: 16),

                      // Add item form or button
                      if (_showAddForm && provider.items.isEmpty)
                        _buildAddItemForm()
                      else if (provider.items.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showAddItemDialog(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить блюдо'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _scanReceipt(context),
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Скан чека'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                  side: const BorderSide(color: AppTheme.accent),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (provider.items.isEmpty && !_showAddForm)
                        _buildAddItemForm(),

                      const SizedBox(height: 20),

                      // Items list
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (provider.items.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: const Text(
                            'Добавьте блюда из счёта или загрузите пример',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ...provider.items.map((item) {
                          final assignedPeople =
                              provider.getPeopleForItem(item.id);
                          return _buildItemTile(
                              item, assignedPeople, provider);
                        }),

                      const SizedBox(height: 20),

                      // Drag target area
                      const Text(
                        'Перетащите блюда на участников',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPeopleDropTargets(provider),

                      // Unassigned info
                      if (provider.items.isNotEmpty &&
                          provider.unassignedItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Осталось распределить: ${unassignedTotal.toStringAsFixed(0)} сом',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border:
                      Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: provider.items.isEmpty ||
                              provider.unassignedItems.isNotEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SummaryScreen(),
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        disabledBackgroundColor:
                            AppTheme.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Итоги',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceCharge(BillProvider provider) {
    const percentages = [0.0, 10.0, 15.0];
    return Container(
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
              const Text(
                'Обслуживание',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ...percentages.map((pct) {
                final isSelected = provider.serviceChargeEnabled &&
                    provider.serviceChargePercent == pct;
                final isZero = pct == 0;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () {
                      if (isZero) {
                        provider.toggleServiceCharge(false);
                        provider.setServiceChargePercent(0);
                      } else {
                        provider.toggleServiceCharge(true);
                        provider.setServiceChargePercent(pct);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : (isZero && !provider.serviceChargeEnabled)
                                ? AppTheme.primary
                                : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ||
                                  (isZero &&
                                      !provider.serviceChargeEnabled)
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isSelected ||
                                  (isZero &&
                                      !provider.serviceChargeEnabled)
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(BillProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _totalRow(
            'Итого:',
            '${provider.subtotal.toStringAsFixed(0)} сом',
          ),
          if (provider.serviceChargeEnabled) ...[
            const SizedBox(height: 6),
            _totalRow(
              '+ Обслуживание (${provider.serviceChargePercent.toStringAsFixed(0)}%):',
              '${provider.serviceChargeAmount.toStringAsFixed(0)} сом',
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Всего:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${provider.total.toStringAsFixed(0)} сом',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
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
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Название блюда',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              hintText: 'Цена (сом)',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _addItem,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Добавить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _nameController.clear();
                    _priceController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _scanReceipt(context),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Сканировать чек'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(
    BillItem item,
    Set<String> assignedPeople,
    BillProvider provider,
  ) {
    final isAssigned = assignedPeople.isNotEmpty;
    return Draggable<BillItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '${item.name}  ${item.price.toStringAsFixed(0)} сом',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _itemCard(item, isAssigned, assignedPeople, provider),
      ),
      child: _itemCard(item, isAssigned, assignedPeople, provider),
    );
  }

  Widget _itemCard(
    BillItem item,
    bool isAssigned,
    Set<String> assignedPeople,
    BillProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAssigned
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAssigned
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          if (assignedPeople.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: assignedPeople.map((pid) {
                  final person = provider.people
                      .firstWhere((p) => p.id == pid);
                  return Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: person.avatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        person.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${item.price.toStringAsFixed(0)} сом',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.removeItem(item.id),
            child: const Icon(
              Icons.delete_outline,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleDropTargets(BillProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
          builder: (context, candidateData, _) {
            final isHovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHovering
                          ? person.avatarColor
                          : person.avatarColor.withValues(alpha: 0.7),
                      border: Border.all(
                        color: isHovering
                            ? Colors.white
                            : person.avatarColor,
                        width: isHovering ? 3 : 2,
                      ),
                      boxShadow: isHovering
                          ? [
                              BoxShadow(
                                color: person.avatarColor
                                    .withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
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
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  if (personTotal > 0)
                    Text(
                      '${personTotal.toStringAsFixed(0)} с',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Future<void> _scanReceipt(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Сканировать чек',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                title: const Text('Камера',
                    style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text('Сфотографировать чек',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.accent),
                title: const Text('Галерея',
                    style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text('Выбрать фото чека',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                'Не удалось распознать позиции. Попробуйте сфотографировать чек ровнее при хорошем освещении.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        context.read<BillProvider>().addItemsFromOcr(items);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добавлено ${items.length} позиций'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сканирования: $e')),
        );
      }
    }
  }

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Добавить блюдо',
            style: TextStyle(color: AppTheme.textPrimary)),
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
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
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
              final price = double.tryParse(
                  priceCtrl.text.replaceAll(',', '.'));
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
}
