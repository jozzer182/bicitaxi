import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../repository/chat_repository.dart';

/// Controller for chat operations within a ride.
class ChatController extends ChangeNotifier {
  ChatController({
    required this.repo,
    required this.rideId,
    required this.currentUserId,
    required this.isClientApp,
  });

  final ChatRepository repo;
  final String rideId;
  final String currentUserId;
  final bool isClientApp;

  List<ChatMessage> messages = [];
  StreamSubscription<List<ChatMessage>>? _subscription;
  bool _isDisposed = false;

  /// Initializes the controller and starts listening to messages.
  void init() {
    _subscription = repo.watchMessages(rideId).listen((newMessages) {
      if (!_isDisposed) {
        messages = newMessages;
        notifyListeners();
      }
    });
  }

  /// Sends a text message.
  Future<void> sendText(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      senderId: currentUserId,
      text: trimmedText,
      sentAt: DateTime.now(),
      isFromClient: isClientApp,
    );

    await repo.sendMessage(message);
  }

  /// Simulates a remote reply after a short delay.
  /// TODO: Remove simulator when real backend is connected.
  Future<void> simulateRemoteReply() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (_isDisposed) return;

    final replies = isClientApp
        ? [
            '¡Estoy en camino!',
            'Llegaré en unos minutos',
            'Ya casi llego al punto de recogida',
            '¿Puedes confirmar la dirección?',
          ]
        : [
            '¡Perfecto, gracias!',
            'Te espero en la esquina',
            'Soy el de la camisa azul',
            'Ya te veo llegando',
          ];

    final replyText = replies[DateTime.now().second % replies.length];

    final reply = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      senderId: isClientApp ? 'driver-demo' : 'client-demo',
      text: replyText,
      sentAt: DateTime.now(),
      isFromClient: !isClientApp,
    );

    await repo.sendMessage(reply);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

