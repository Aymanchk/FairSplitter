import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isGuest) {
        context.read<GroupProvider>().loadGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final groupProvider = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Группы друзей'),
        actions: [
          if (!auth.isGuest)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateGroupDialog(),
            ),
        ],
      ),
      body: auth.isGuest
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_outlined,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Войдите для управления группами',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : groupProvider.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primary))
              : groupProvider.groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_add,
                              size: 64,
                              color: AppTheme.textSecondary
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Нет групп',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Создайте группу, чтобы быстро\nдобавлять друзей в счёт',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () =>
                                _showCreateGroupDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Создать группу'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => groupProvider.loadGroups(),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupProvider.groups.length,
                        itemBuilder: (context, index) {
                          final group = groupProvider.groups[index];
                          return _GroupCard(
                            group: group,
                            onEdit: () =>
                                _showEditGroupDialog(group),
                            onDelete: () async {
                              final id = group['id'] as int;
                              await groupProvider.deleteGroup(id);
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final searchController = TextEditingController();
    final selectedMembers = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> searchResults = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Text(
                'Новая группа',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Название группы',
                  hintText: 'Напр: Одногруппники',
                  prefixIcon: Icon(Icons.group),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Поиск друзей',
                  hintText: 'Имя или email',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) async {
                  if (query.length < 2) {
                    setModalState(() => searchResults = []);
                    return;
                  }
                  try {
                    final auth = context.read<AuthProvider>();
                    final results = await auth.api.searchUsers(query);
                    setModalState(() => searchResults = results);
                  } catch (_) {}
                },
              ),
              if (searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (_, i) {
                      final user = searchResults[i];
                      final alreadyAdded = selectedMembers
                          .any((m) => m['id'] == user['id']);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            (user['name']?.toString() ?? '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text(user['name']?.toString() ?? '',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14)),
                        subtitle: Text(user['email']?.toString() ?? '',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                        trailing: alreadyAdded
                            ? const Icon(Icons.check,
                                color: AppTheme.green, size: 18)
                            : null,
                        onTap: alreadyAdded
                            ? null
                            : () {
                                setModalState(
                                    () => selectedMembers.add(user));
                              },
                      );
                    },
                  ),
                ),
              ],
              if (selectedMembers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedMembers.map((m) {
                    return Chip(
                      backgroundColor: AppTheme.surfaceLight,
                      label: Text(m['name']?.toString() ?? '',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setModalState(
                            () => selectedMembers.remove(m));
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final memberIds = selectedMembers
                        .map((m) => m['id'] as int)
                        .toList();
                    final provider = context.read<GroupProvider>();
                    await provider.createGroup(
                      name: nameController.text.trim(),
                      memberIds: memberIds,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Создать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditGroupDialog(Map<String, dynamic> group) {
    final nameController =
        TextEditingController(text: group['name']?.toString() ?? '');
    final members =
        List<Map<String, dynamic>>.from(group['members'] ?? []);
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Text(
                'Редактировать группу',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Название',
                  prefixIcon: Icon(Icons.group),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Добавить участника',
                  hintText: 'Имя или email',
                  prefixIcon: Icon(Icons.person_add),
                ),
                onChanged: (query) async {
                  if (query.length < 2) {
                    setModalState(() => searchResults = []);
                    return;
                  }
                  try {
                    final auth = context.read<AuthProvider>();
                    final results = await auth.api.searchUsers(query);
                    setModalState(() => searchResults = results);
                  } catch (_) {}
                },
              ),
              if (searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (_, i) {
                      final user = searchResults[i];
                      final alreadyAdded =
                          members.any((m) => m['id'] == user['id']);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            (user['name']?.toString() ?? '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text(user['name']?.toString() ?? '',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14)),
                        trailing: alreadyAdded
                            ? const Icon(Icons.check,
                                color: AppTheme.green, size: 18)
                            : null,
                        onTap: alreadyAdded
                            ? null
                            : () {
                                setModalState(() => members.add(user));
                              },
                      );
                    },
                  ),
                ),
              ],
              if (members.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Участники:',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((m) {
                    return Chip(
                      backgroundColor: AppTheme.surfaceLight,
                      label: Text(m['name']?.toString() ?? '',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setModalState(() => members.remove(m));
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final memberIds =
                        members.map((m) => m['id'] as int).toList();
                    final provider = context.read<GroupProvider>();
                    await provider.updateGroup(
                      groupId: group['id'] as int,
                      name: nameController.text.trim(),
                      memberIds: memberIds,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = group['name']?.toString() ?? '';
    final members =
        List<Map<String, dynamic>>.from(group['members'] ?? []);
    final memberCount = group['member_count'] as int? ?? members.length;

    return Container(
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
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group,
                    color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$memberCount участников',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppTheme.textSecondary),
                color: AppTheme.surfaceLight,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить группу?'),
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
                                style:
                                    TextStyle(color: AppTheme.error)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Редактировать',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить',
                        style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
            ],
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: members.take(6).map((m) {
                final mName = m['name']?.toString() ?? '?';
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    mName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
