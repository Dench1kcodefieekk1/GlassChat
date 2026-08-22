/// Core data models mirroring the native GlassChat Swift models.
library models;

class User {
  final String id;
  final String name;
  final String username;
  final String phone;
  final bool isVerified;
  final bool isOnline;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    this.isVerified = false,
    this.isOnline = false,
  });

  User copyWith({
    String? name,
    String? username,
    String? phone,
    bool? isVerified,
    bool? isOnline,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        username: username ?? this.username,
        phone: phone ?? this.phone,
        isVerified: isVerified ?? this.isVerified,
        isOnline: isOnline ?? this.isOnline,
      );
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });
}

class Chat {
  final String id;
  final String title;
  final String? botId;
  final List<Message> messages;

  Chat({required this.id, required this.title, this.botId, List<Message>? messages})
      : messages = messages ?? [];

  bool get isSystemBot => botId != null;
}
