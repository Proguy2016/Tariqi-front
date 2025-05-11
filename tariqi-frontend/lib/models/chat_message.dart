class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      senderId: json['sender'] ?? '',
      senderName: json['senderType'] ?? '',
      message: json['content'] ?? '',
      createdAt: DateTime.parse(json['timestamp']),
    );
  }
} 