class ChatMessage {
  final String id;
  final String eventId;
  final String userId;
  final String username;
  final String avatarPath;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.username,
    required this.avatarPath,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
      avatarPath: json['avatarPath'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
