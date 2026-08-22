import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/glass.dart';
import '../core/theme.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';

/// Chat room: contact header with call icons, bubble stream with delivery
/// status icons, and a composer with attachments + voice trigger.
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(ChatProvider provider) {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    provider.sendMessage(widget.chatId, text);
    _draft.clear();
    _jumpToBottom();
  }

  void _comingSoon(String feature) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final chat = provider.chatById(widget.chatId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: chat.peer.name,
              size: 36,
              isOnline: chat.isOnline,
              isVerified: chat.peer.isVerified,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          chat.peer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (chat.peer.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified_rounded,
                              size: 15, color: AppTheme.accent),
                        ),
                    ],
                  ),
                  Text(
                    chat.isOnline ? 'online' : chat.peer.lastSeenLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: chat.isOnline
                          ? AppTheme.online
                          : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            tooltip: 'Call',
            onPressed: () => _comingSoon('Calls'),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Video',
            onPressed: () => _comingSoon('Video calls'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: chat.messages.length,
              itemBuilder: (context, index) =>
                  _Bubble(message: chat.messages[index]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    tooltip: 'Attach',
                    onPressed: () => _comingSoon('Attachments'),
                  ),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: const BorderRadius.all(Radius.circular(22)),
                      child: TextField(
                        controller: _draft,
                        onSubmitted: (_) => _send(provider),
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
                    onLongPress: () => _comingSoon('Voice message'),
                    onTap: () => _send(provider),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          AppTheme.accent,
                          Theme.of(context).colorScheme.tertiary,
                        ]),
                      ),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _draft,
                        builder: (context, value, _) => Icon(
                          value.text.trim().isEmpty
                              ? Icons.mic_rounded
                              : Icons.arrow_upward_rounded,
                          color: Colors.white,
                        ),
                      ),
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

/// Telegram-style bubble with tight padding, time, and status icon.
class _Bubble extends StatelessWidget {
  final Message message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? AppTheme.accent : AppTheme.bubbleIncoming,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: mine ? const Radius.circular(18) : const Radius.circular(5),
            bottomRight: mine ? const Radius.circular(5) : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.timeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: mine ? Colors.white70 : Colors.white38,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.watch_later_outlined, size: 13, color: Colors.white54);
      case MessageStatus.sent:
        return const Icon(Icons.done_rounded, size: 13, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 13, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 13, color: Colors.white);
    }
  }
}
