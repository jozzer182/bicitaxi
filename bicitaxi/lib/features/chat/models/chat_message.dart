/// A chat message in a ride conversation.
/// TODO: Store in Firestore in future backend.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isFromClient,
  });

  final String id;
  final String rideId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isFromClient;

  /// Converts to a map suitable for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'senderId': senderId,
      'text': text,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'isFromClient': isFromClient,
    };
  }

  /// Creates a ChatMessage from a map (e.g., from Firestore).
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      rideId: map['rideId'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      sentAt: DateTime.fromMillisecondsSinceEpoch(map['sentAt'] as int),
      isFromClient: map['isFromClient'] as bool,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? rideId,
    String? senderId,
    String? text,
    DateTime? sentAt,
    bool? isFromClient,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isFromClient: isFromClient ?? this.isFromClient,
    );
  }
}

