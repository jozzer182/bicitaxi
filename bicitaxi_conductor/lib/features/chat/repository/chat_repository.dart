import '../models/chat_message.dart';

/// Abstract repository for chat operations.
/// TODO: Replace with Firestore-based implementation.
abstract class ChatRepository {
  /// Sends a message to a ride chat.
  Future<void> sendMessage(ChatMessage message);

  /// Watches messages for a specific ride.
  Stream<List<ChatMessage>> watchMessages(String rideId);

  /// Disposes resources when no longer needed.
  void dispose();
}

