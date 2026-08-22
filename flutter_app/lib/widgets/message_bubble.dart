import 'package:flutter/material.dart';

import '../models/models.dart';

/// Telegram-style chat bubble: mine (accent, right) vs incoming (glass, left).
class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : const Color(0xFF1B2230),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: mine ? const Radius.circular(18) : const Radius.circular(5),
            bottomRight: mine ? const Radius.circular(5) : const Radius.circular(18),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 15, height: 1.35),
        ),
      ),
    );
  }
}
