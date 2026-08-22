import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';

/// Global chat state: the active session user (the single source of truth
/// for the dynamically bound phone number), seeded chats, message sending
/// with simulated delivery status progression, and unread counts.
class ChatProvider extends ChangeNotifier {
  ChatProvider() {
    _seed();
  }

  late User me;
  final List<Chat> chats = [];

  void _seed() {
    // The phone entered at registration — profile binds directly to it.
    me = const User(
      id: 'me',
      name: 'Alex',
      username: 'alex',
      phone: '+380 68 777 77 77',
      bio: 'Building delightful iOS things.',
      userIdTag: 'user-me-8841',
      registrationLabel: 'August 2026',
      isOnline: true,
    );

    final now = DateTime.now();
    DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));

    final sarah = const User(
      id: 'sarah',
      name: 'Sarah Chen',
      username: 'sarahc',
      phone: '+380 63 111 22 33',
      bio: 'Product designer. Glass enthusiast.',
      isVerified: true,
      isOnline: true,
    );
    final john = const User(
      id: 'john',
      name: 'John Carter',
      username: 'johnc',
      phone: '+380 63 222 33 44',
      bio: 'Swift, coffee, repeat.',
      lastSeenLabel: 'last seen 42 minutes ago',
    );
    final maya = const User(
      id: 'maya',
      name: 'Maya Patel',
      username: 'mayap',
      phone: '+380 63 333 44 55',
      bio: 'Design systems and motion.',
      isOnline: true,
    );

    chats.addAll([
      Chat(
        id: 'chat-sarah',
        peer: sarah,
        isPinned: true,
        unreadCount: 2,
        messages: [
          Message(id: 's1', text: 'Did you see the new Liquid Glass headers?', isMine: false, createdAt: ago(190), status: MessageStatus.read),
          Message(id: 's2', text: 'Looks unreal 🔥', isMine: true, createdAt: ago(186), status: MessageStatus.read),
          Message(id: 's3', text: 'Sending you the concept file in a sec', isMine: false, createdAt: ago(9), status: MessageStatus.read),
        ],
      ),
      Chat(
        id: 'chat-john',
        peer: john,
        unreadCount: 1,
        messages: [
          Message(id: 'j1', text: 'Coffee after standup?', isMine: false, createdAt: ago(120), status: MessageStatus.read),
          Message(id: 'j2', text: 'Погнали ☕️', isMine: false, createdAt: ago(38), status: MessageStatus.read),
        ],
      ),
      Chat(
        id: 'chat-maya',
        peer: maya,
        messages: [
          Message(id: 'm1', text: 'The spring curves feel just right now', isMine: false, createdAt: ago(1400), status: MessageStatus.read),
          Message(id: 'm2', text: 'Agreed!', isMine: true, createdAt: ago(1395), status: MessageStatus.read),
        ],
      ),
    ]);
  }

  Chat chatById(String id) => chats.firstWhere((chat) => chat.id == id);

  /// Clears the unread badge when a chat is opened.
  void markRead(String chatId) {
    final chat = chatById(chatId);
    final canClear = chat.unreadCount > 0;
    if (!canClear) return;
    final index = chats.indexOf(chat);
    chats[index] = Chat(
      id: chat.id,
      peer: chat.peer,
      messages: chat.messages,
      isPinned: chat.isPinned,
    );
    notifyListeners();
  }

  /// Sends a message and simulates sending → sent → delivered → read.
  void sendMessage(String chatId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final chat = chatById(chatId);
    final message = Message(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(999)}',
      text: trimmed,
      isMine: true,
      createdAt: DateTime.now(),
    );
    final index = chats.indexOf(chat);
    chats[index] = Chat(
      id: chat.id,
      peer: chat.peer,
      messages: [...chat.messages, message],
      isPinned: chat.isPinned,
      unreadCount: chat.unreadCount,
    );
    notifyListeners();

    _progressStatus(chatId, message.id);
  }

  static final Random _random = Random();

  void _progressStatus(String chatId, String messageId) {
    Future.delayed(const Duration(milliseconds: 400), () => _setStatus(chatId, messageId, MessageStatus.sent));
    Future.delayed(const Duration(milliseconds: 1100), () => _setStatus(chatId, messageId, MessageStatus.delivered));
    Future.delayed(const Duration(milliseconds: 1800), () => _setStatus(chatId, messageId, MessageStatus.read));
  }

  void _setStatus(String chatId, String messageId, MessageStatus status) {
    final chat = chatById(chatId);
    final index = chats.indexOf(chat);
    var changed = false;
    final updated = chat.messages.map((message) {
      if (message.id == messageId && message.status != status) {
        changed = true;
        return message.copyWith(status: status);
      }
      return message;
    }).toList();
    if (!changed) return;
    chats[index] = Chat(
      id: chat.id,
      peer: chat.peer,
      messages: updated,
      isPinned: chat.isPinned,
      unreadCount: chat.unreadCount,
    );
    notifyListeners();
  }
}
