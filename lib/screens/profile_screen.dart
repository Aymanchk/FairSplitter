import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'stats_screen.dart';
import 'groups_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.userName ?? '';
    _emailController.text = auth.userEmail ?? '';
    _phoneController.text = auth.userPhone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.uploadAvatar(File(picked.path));
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото обновлено')),
      );
    }
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Ошибка')),
        );
      }
    }
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'Профиль',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),

              // Avatar
              GestureDetector(
                onTap: auth.isGuest ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: auth.userAvatarUrl != null
                          ? CachedNetworkImageProvider(auth.userAvatarUrl!)
                          : null,
                      child: _isUploadingAvatar
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : auth.userAvatarUrl == null
                              ? Text(
                                  (auth.userName ?? 'G')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                    ),
                    if (!auth.isGuest)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.background, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                auth.userName ?? 'Гость',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (!auth.isGuest)
                Text(
                  auth.userEmail ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              const SizedBox(height: 24),

              // Quick actions
              if (!auth.isGuest) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Статистика расходов',
                        color: AppTheme.primary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const StatsScreen()),
                        ),
                      ),
                      const Divider(color: AppTheme.border, height: 1),
                      _menuItem(
                        icon: Icons.group,
                        label: 'Группы друзей',
                        color: AppTheme.accent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const GroupsScreen()),
                        ),
                      ),
                      const Divider(color: AppTheme.border, height: 1),
                      Consumer<NotificationProvider>(
                        builder: (context, notifProvider, _) {
                          return _menuItem(
                            icon: Icons.notifications_outlined,
                            label: 'Уведомления',
                            color: AppTheme.green,
                            badge: notifProvider.unreadCount,
                            onTap: () {
                              notifProvider.loadNotifications();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen()),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (auth.isGuest) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_off_outlined,
                          color: AppTheme.textSecondary, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Вы вошли как гость',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Зарегистрируйтесь, чтобы сохранять историю и общаться с друзьями',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _logout,
                          child: const Text('Зарегистрироваться'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Editable fields
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildField(
                        icon: Icons.person_outline,
                        label: 'Имя',
                        controller: _nameController,
                        enabled: _isEditing,
                      ),
                      const Divider(color: AppTheme.border, height: 24),
                      _buildField(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Divider(color: AppTheme.border, height: 24),
                      _buildField(
                        icon: Icons.phone_outlined,
                        label: 'Телефон',
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Edit / Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _isEditing
                      ? Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () {
                                    _nameController.text = auth.userName ?? '';
                                    _emailController.text = auth.userEmail ?? '';
                                    _phoneController.text = auth.userPhone ?? '';
                                    setState(() => _isEditing = false);
                                  },
                                  child: const Text('Отмена'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: auth.isLoading ? null : _saveProfile,
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Сохранить'),
                                ),
                              ),
                            ),
                          ],
                        )
                      : FilledButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Редактировать'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.surfaceLight,
                          ),
                        ),
                ),
                const SizedBox(height: 32),

                // Logout
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: AppTheme.error),
                    label: const Text('Выйти из аккаунта',
                        style: TextStyle(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: enabled
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: label,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      controller.text.isEmpty ? '—' : controller.text,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
