import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import 'split_screen.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final auth = context.read<AuthProvider>();
      if (auth.isGuest) return;

      setState(() => _isSearching = true);
      try {
        final results = await auth.api.searchUsers(query.trim());
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _addPerson() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<BillProvider>().addPerson(name);
    _nameController.clear();
    setState(() => _searchResults = []);
  }

  void _showGroupPickerDialog() {
    final groupProvider = context.read<GroupProvider>();
    groupProvider.loadGroups();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<GroupProvider>(
          builder: (ctx, gp, _) {
            if (gp.isLoading) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }
            if (gp.groups.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_off,
                          color: AppTheme.textSecondary, size: 40),
                      const SizedBox(height: 12),
                      const Text('Нет групп',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text(
                        'Создайте группу в разделе Профиль',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Выберите группу',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...gp.groups.map((group) {
                    final members = List<Map<String, dynamic>>.from(
                        group['members'] ?? []);
                    final name = group['name']?.toString() ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.group,
                            color: AppTheme.accent, size: 20),
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500)),
                      subtitle: Text('${members.length} участников',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      onTap: () {
                        final billProvider = context.read<BillProvider>();
                        for (final member in members) {
                          final alreadyAdded = billProvider.people
                              .any((p) => p.userId == member['id']);
                          if (!alreadyAdded) {
                            billProvider.addPerson(
                              member['name'] as String? ?? '',
                              userId: member['id'] as int?,
                              avatarUrl: member['avatar'] as String?,
                            );
                          }
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Добавлено из "$name"')),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addFromSearch(Map<String, dynamic> user) {
    final provider = context.read<BillProvider>();
    // Don't add the same user twice
    final alreadyAdded = provider.people.any((p) => p.userId == user['id']);
    if (alreadyAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Участник уже добавлен')),
      );
      return;
    }
    provider.addPerson(
      user['name'] as String,
      userId: user['id'] as int,
      avatarUrl: user['avatar'] as String?,
    );
    _nameController.clear();
    setState(() => _searchResults = []);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Title
              Text(
                'Fair Splitter',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Добавьте участников',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Name input + add button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: auth.isGuest
                            ? 'Имя участника'
                            : 'Имя или поиск по email',
                        prefixIcon: const Icon(Icons.person_outline),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _addPerson(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: FilledButton(
                      onPressed: _addPerson,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      auth.isGuest
                          ? 'Добавьте минимум 2 участников'
                          : 'Введите имя или найдите пользователя',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (!auth.isGuest)
                    TextButton.icon(
                      onPressed: () => _showGroupPickerDialog(),
                      icon: const Icon(Icons.group, size: 16),
                      label: const Text('Из группы', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),

              // Search results dropdown
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final avatarUrl = user['avatar'] as String?;
                      final name = user['name'] as String;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          backgroundImage: avatarUrl != null
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text(
                          user['email'] as String? ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.person_add_outlined,
                            color: AppTheme.accent, size: 20),
                        onTap: () => _addFromSearch(user),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // People list
              Expanded(
                child: provider.people.isEmpty
                    ? const SizedBox()
                    : ListView.builder(
                        itemCount: provider.people.length,
                        itemBuilder: (context, index) {
                          final person = provider.people[index];
                          final isRegistered = person.userId != null;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: person.avatarColor,
                                backgroundImage: person.avatarUrl != null
                                    ? CachedNetworkImageProvider(
                                        person.avatarUrl!)
                                    : null,
                                child: person.avatarUrl == null
                                    ? Text(
                                        person.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    person.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isRegistered) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified,
                                        color: AppTheme.accent, size: 16),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close,
                                    color: AppTheme.textSecondary, size: 20),
                                onPressed: () =>
                                    provider.removePerson(person.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Next button
              Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: provider.people.length < 2
                        ? null
                        : () {
                            provider.reset(keepPeople: true);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SplitScreen(),
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
                          'Далее',
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
            ],
          ),
        ),
      ),
    );
  }
}
