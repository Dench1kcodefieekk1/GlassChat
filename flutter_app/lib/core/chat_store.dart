import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// In-memory chat store: the active session user, bot chats, and message
/// posting (receipts). Mirrors the native DataStore system-bot behavior.
class ChatStore extends ChangeNotifier {
  ChatStore._() {
    _seed();
  }

  static final ChatStore I = ChatStore._();

  static const String walletBotId = 'user-wallet';
  static const String fragmentBotId = 'user-fragment';
  static const String walletChatId = 'chat-wallet';
  static const String fragmentChatId = 'chat-fragment';

  late User me;
  final List<Chat> chats = <Chat>[];

  void _seed() {
    // The phone entered at registration is the single source of truth;
    // profile views bind directly to it (no static fallbacks).
    me = const User(
      id: 'me',
      name: 'Alex',
      username: 'alex',
      phone: '+380 68 777 77 77',
      isOnline: true,
    );

    final now = DateTime.now();
    chats.addAll([
      Chat(
        id: walletChatId,
        title: 'Wallet',
        botId: walletBotId,
        messages: [
          Message(
            id: 'w1',
            chatId: walletChatId,
            senderId: walletBotId,
            text: 'Ваш кошелёк GlassChat. Откройте мини-приложение ниже, чтобы управлять балансом \$TYP0K и USDT.',
            createdAt: now,
            isMine: false,
          ),
        ],
      ),
      Chat(
        id: fragmentChatId,
        title: 'Fragment Market',
        botId: fragmentBotId,
        messages: [
          Message(
            id: 'f1',
            chatId: fragmentChatId,
            senderId: fragmentBotId,
            text: 'Fragment — маркетплейс уникальных юзернеймов. Откройте мини-приложение ниже, чтобы выкупить редкий юзернейм.',
            createdAt: now,
            isMine: false,
          ),
        ],
      ),
      Chat(
        id: 'chat-sarah',
        title: 'Sarah Chen',
        messages: [
          Message(
            id: 's1',
            chatId: 'chat-sarah',
            senderId: 'sarah',
            text: 'Привет! Видела новый кошелёк? 👛',
            createdAt: now,
            isMine: false,
          ),
          Message(
            id: 's2',
            chatId: 'chat-sarah',
            senderId: 'me',
            text: 'Да, крутая штука!',
            createdAt: now,
            isMine: true,
          ),
        ],
      ),
    ]);
  }

  Chat chatById(String id) => chats.firstWhere((chat) => chat.id == id);

  /// Posts a message (user sends, bot receipts) and notifies all listeners.
  void postMessage({required String chatId, required String senderId, required String text}) {
    chatById(chatId).messages.add(
          Message(
            id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
            chatId: chatId,
            senderId: senderId,
            text: text,
            createdAt: DateTime.now(),
            isMine: senderId == me.id,
          ),
        );
    notifyListeners();
  }

  /// Binds a purchased Fragment handle to the active profile.
  void setUsername(String newUsername) {
    me = me.copyWith(username: newUsername);
    notifyListeners();
  }
}
