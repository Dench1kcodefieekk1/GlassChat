import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/chat_store.dart';
import '../widgets/glass.dart';
import '../widgets/message_bubble.dart';
import 'fragment_sheet.dart';
import 'wallet_sheet.dart';

/// Chat stream with the persistent mini-app launcher pill for the
/// @wallet / @fragment system bot chats.
class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _draft = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(ChatStore store) {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    store.postMessage(chatId: widget.chatId, senderId: store.me.id, text: text);
    _draft.clear();
    _jumpToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatStore>();
    final chat = store.chatById(widget.chatId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chat.title),
            if (chat.isSystemBot)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child:
                    Icon(Icons.verified_rounded, size: 18, color: Color(0xFF3D9BFF)),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chat.messages.length,
              itemBuilder: (context, index) =>
                  MessageBubble(message: chat.messages[index]),
            ),
          ),
          if (chat.botId == ChatStore.walletBotId)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MiniAppPill(
                title: '👛 Open Wallet Mini App',
                onTap: () => showWalletSheet(context),
              ),
            ),
          if (chat.botId == ChatStore.fragmentBotId)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MiniAppPill(
                title: '🌐 Open Fragment Mini App',
                onTap: () => showFragmentSheet(context),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(24)),
                      child: TextField(
                        controller: _draft,
                        onSubmitted: (_) => _send(store),
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Message',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(store),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ]),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
