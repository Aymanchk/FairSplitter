import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'split_screen.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<BillProvider>().addPerson(name);
    _nameController.clear();
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
              const SizedBox(height: 24),
              // Header with settings
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppTheme.textSecondary),
                    onPressed: () {
                      _showSettingsMenu(context, auth);
                    },
                  ),
                ],
              ),

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
                      decoration: const InputDecoration(
                        hintText: 'Имя участника',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
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
              Text(
                'Добавьте минимум 2 участников',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // People list
              Expanded(
                child: provider.people.isEmpty
                    ? const SizedBox()
                    : ListView.builder(
                        itemCount: provider.people.length,
                        itemBuilder: (context, index) {
                          final person = provider.people[index];
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
                                child: Text(
                                  person.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                person.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
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
                padding: const EdgeInsets.only(bottom: 24),
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

  void _showSettingsMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth.userName != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    auth.userName![0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(auth.userName!,
                    style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(
                  auth.isGuest ? 'Гость' : auth.userEmail ?? '',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            const Divider(color: AppTheme.border),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: AppTheme.textSecondary),
              title: const Text('Выйти',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                auth.logout();
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
