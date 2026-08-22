import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/chat_store.dart';
import '../widgets/glass.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

/// Chat list home: lazy-built glass chat cards + profile entry.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatStore>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('GlassChat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: store.chats.length,
        itemBuilder: (context, index) {
          final chat = store.chats[index];
          final lastMessage = chat.messages.isEmpty ? '' : chat.messages.last.text;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  child: chat.isSystemBot
                      ? const Icon(Icons.smart_toy_rounded, color: Colors.white)
                      : Text(
                          chat.title.isNotEmpty ? chat.title[0] : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        chat.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (chat.isSystemBot)
                      const Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Icon(Icons.verified_rounded,
                            size: 16, color: Color(0xFF3D9BFF)),
                      ),
                  ],
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatScreen(chatId: chat.id),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
