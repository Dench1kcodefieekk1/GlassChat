/// Delivery status driving the bubble status icons.
enum MessageStatus { sending, sent, delivered, read }

/// A single chat message.
class Message {
  final String id;
  final String text;
  final bool isMine;
  final DateTime createdAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.text,
    required this.isMine,
    required this.createdAt,
    this.status = MessageStatus.sending,
  });

  Message copyWith({MessageStatus? status}) => Message(
        id: id,
        text: text,
        isMine: isMine,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  String get timeLabel =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}
