import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import 'chat_providers.dart';
import 'chat_socket.dart';

/// Danh sách hội thoại (của người mua lẫn người bán).
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(chatSocketProvider); // giữ socket sống để cập nhật real-time
    final async = ref.watch(conversationsProvider);
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.messages)),
      body: AsyncView(
        value: async,
        loading: const SkeletonList(count: 6),
        onRetry: () => ref.invalidate(conversationsProvider),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(message: s.noConversations);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
              ref.invalidate(chatUnreadProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) => FadeSlideIn(index: i, child: _ConversationTile(items[i])),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile(this.c);
  final ChatConversation c;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.accent.withValues(alpha: 0.14),
        backgroundImage:
            (c.avatarUrl != null && c.avatarUrl!.isNotEmpty) ? NetworkImage(c.avatarUrl!) : null,
        child: (c.avatarUrl == null || c.avatarUrl!.isEmpty)
            ? Text(c.title.isNotEmpty ? c.title.characters.first.toUpperCase() : '?',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(c.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.w600)),
      subtitle: Text(c.lastMessage ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: c.unread > 0 ? context.c.textPrimary : context.c.textSecondary)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.lastMessageAt != null)
            Text(formatDateTime(c.lastMessageAt!).split(' ').first,
                style: TextStyle(fontSize: 11, color: context.c.textSecondary)),
          const SizedBox(height: 4),
          if (c.unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text('${c.unread}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFFFFFFF), fontSize: 11, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      onTap: () => context.push('/chat/${c.id}', extra: c.title),
    );
  }
}
