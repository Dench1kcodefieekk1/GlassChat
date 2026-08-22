import 'message.dart';
import 'user.dart';

/// A conversation: peer + stream + unread state.
class Chat {
  final String id;
  final User peer;
  final List<Message> messages;
  final bool isPinned;
  final int unreadCount;

  Chat({
    required this.id,
    required this.peer,
    List<Message>? messages,
    this.isPinned = false,
    this.unreadCount = 0,
  }) : messages = messages ?? [];

  bool get isOnline => peer.isOnline;

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  String get listTimestamp {
    final message = lastMessage;
    if (message == null) return '';
    final now = DateTime.now();
    final local = message.createdAt;
    if (now.day == local.day && now.month == local.month) return message.timeLabel;
    return '${local.day}.${local.month.toString().padLeft(2, '0')}';
  }
}
