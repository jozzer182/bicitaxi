import 'dart:async';
import '../models/chat_message.dart';
import 'chat_repository.dart';

/// In-memory implementation of ChatRepository for development/testing.
/// TODO: Replace with Firestore-based implementation.
class InMemoryChatRepository implements ChatRepository {
  final Map<String, List<ChatMessage>> _messagesByRide = {};
  final Map<String, StreamController<List<ChatMessage>>> _controllers = {};

  StreamController<List<ChatMessage>> _getController(String rideId) {
    if (!_controllers.containsKey(rideId)) {
      _controllers[rideId] = StreamController<List<ChatMessage>>.broadcast();
      // Emit initial empty list
      _controllers[rideId]!.add(_messagesByRide[rideId] ?? []);
    }
    return _controllers[rideId]!;
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    // Ensure list exists for this ride
    _messagesByRide.putIfAbsent(message.rideId, () => []);
    _messagesByRide[message.rideId]!.add(message);

    // Sort by time
    _messagesByRide[message.rideId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    // Notify listeners
    final controller = _getController(message.rideId);
    if (!controller.isClosed) {
      controller.add(List.from(_messagesByRide[message.rideId]!));
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String rideId) {
    // Ensure initial messages are available
    _messagesByRide.putIfAbsent(rideId, () => []);
    return _getController(rideId).stream;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

