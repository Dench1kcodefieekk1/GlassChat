import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/glass.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Home: search bar + chat list with online dots, timestamps, unread badges.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final chats = provider.chats
        .where((chat) =>
            _query.isEmpty ||
            chat.peer.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => _push(const ProfileScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _push(const SettingsScreen()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search chats',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: chats.length,
              itemBuilder: (context, index) => _ChatRow(
                chat: chats[index],
                onTap: () {
                  provider.markRead(chats[index].id);
                  _push(ChatScreen(chatId: chats[index].id));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _ChatRow extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _ChatRow({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: UserAvatar(
            name: chat.peer.name,
            size: 52,
            isOnline: chat.isOnline,
            isVerified: chat.peer.isVerified,
          ),
          title: Row(
            children: [
              if (chat.isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.push_pin_rounded,
                      size: 13, color: Colors.white38),
                ),
              Expanded(
                child: Text(
                  chat.peer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                chat.listTimestamp,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  chat.lastMessage?.text ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ),
              const SizedBox(width: 8),
              UnreadBadge(count: chat.unreadCount),
            ],
          ),
        ),
      ),
    );
  }
}
