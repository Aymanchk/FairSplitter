import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isGuest) {
        context.read<ChatProvider>().loadRooms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Чаты',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (!auth.isGuest)
                    IconButton(
                      icon: const Icon(Icons.edit_square,
                          color: AppTheme.accent),
                      onPressed: () => _showNewChatDialog(context),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: auth.isGuest
                    ? const _GuestPlaceholder()
                    : chat.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary))
                        : chat.rooms.isEmpty
                            ? const _EmptyPlaceholder()
                            : RefreshIndicator(
                                color: AppTheme.primary,
                                onRefresh: () => chat.loadRooms(),
                                child: ListView.builder(
                                  itemCount: chat.rooms.length,
                                  itemBuilder: (context, index) {
                                    return _ChatRoomTile(
                                      room: chat.rooms[index],
                                      currentUserId: auth.userId,
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Новый чат',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Поиск по имени или email',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) async {
                  if (query.trim().length < 2) {
                    setSheetState(() => results = []);
                    return;
                  }
                  setSheetState(() => searching = true);
                  try {
                    final auth = context.read<AuthProvider>();
                    final r = await auth.api.searchUsers(query.trim());
                    setSheetState(() {
                      results = r;
                      searching = false;
                    });
                  } catch (e) {
                    setSheetState(() => searching = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              if (searching)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final user = results[i];
                    final avatarUrl = user['avatar'] as String?;
                    final name = user['name'] as String;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? Text(name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white))
                            : null,
                      ),
                      title: Text(name,
                          style: const TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text(user['email'] as String? ?? '',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        final chatProvider = context.read<ChatProvider>();
                        final room = await chatProvider
                            .getOrCreateRoom(user['id'] as int);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                roomId: room['id'] as int,
                                otherUserName: name,
                                otherAvatarUrl: avatarUrl,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final Map<String, dynamic> room;
  final int? currentUserId;

  const _ChatRoomTile({required this.room, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final participants =
        List<Map<String, dynamic>>.from(room['participants'] ?? []);
    final other = participants.firstWhere(
      (p) => p['id'] != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : {'name': '?'},
    );
    final name = other['name'] as String? ?? '?';
    final avatarUrl = other['avatar'] as String?;
    final lastMsg = room['last_message'] as Map<String, dynamic>?;
    final unread = room['unread_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          backgroundImage:
              avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            )),
        subtitle: lastMsg != null
            ? Text(
                lastMsg['text'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unread > 0
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 13,
                ),
              )
            : const Text('Нет сообщений',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        trailing: unread > 0
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              )
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                roomId: room['id'] as int,
                otherUserName: name,
                otherAvatarUrl: avatarUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuestPlaceholder extends StatelessWidget {
  const _GuestPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text('Войдите в аккаунт',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          SizedBox(height: 4),
          Text('Чтобы общаться с друзьями',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text('Пока нет чатов',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          SizedBox(height: 4),
          Text('Нажмите + чтобы начать общение',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}
