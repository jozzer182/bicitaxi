import 'chat_message.dart';

/// A chat thread containing all messages for a ride.
/// TODO: May be used for Firestore subcollection organization.
class ChatThread {
  ChatThread({
    required this.rideId,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  final String rideId;
  final List<ChatMessage> messages;

  /// Adds a message to the thread.
  void addMessage(ChatMessage message) {
    messages.add(message);
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  /// Gets the most recent message, if any.
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Gets the message count.
  int get messageCount => messages.length;
}

