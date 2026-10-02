class WaMessage {
  final String sender;
  final String text;
  final DateTime receivedAt;
  bool isRead;

  WaMessage({
    required this.sender,
    required this.text,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'text': text,
        'receivedAt': receivedAt.millisecondsSinceEpoch,
        'isRead': isRead,
      };

  factory WaMessage.fromJson(Map<String, dynamic> j) => WaMessage(
        sender: j['sender'] as String,
        text: j['text'] as String,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(j['receivedAt'] as int),
        isRead: (j['isRead'] as bool?) ?? false,
      );

  /// Human-readable time label ("now", "5m", "2h", "3d", "12/6")
  String get timeLabel {
    final diff = DateTime.now().difference(receivedAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${receivedAt.day}/${receivedAt.month}';
  }
}
