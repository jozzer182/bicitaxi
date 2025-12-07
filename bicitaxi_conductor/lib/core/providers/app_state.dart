import 'package:flutter/material.dart';
import '../../features/rides/controllers/driver_ride_controller.dart';
import '../../features/rides/repository/ride_repository.dart';
import '../../features/rides/repository/in_memory_ride_repository.dart';
import '../../features/chat/repository/chat_repository.dart';
import '../../features/chat/repository/in_memory_chat_repository.dart';

/// Global singleton instances for app state.
/// TODO: Swap InMemoryRideRepository and InMemoryChatRepository for Firebase implementation and proper DI.
final _sharedRideRepo = InMemoryRideRepository();
final _sharedChatRepo = InMemoryChatRepository();
final _sharedController = DriverRideController(repo: _sharedRideRepo);

/// Provides app-wide state to the widget tree.
class AppState extends InheritedWidget {
  const AppState({
    super.key,
    required super.child,
  });

  /// Gets the shared ride repository.
  RideRepository get rideRepository => _sharedRideRepo;

  /// Gets the shared chat repository.
  ChatRepository get chatRepository => _sharedChatRepo;

  /// Gets the shared ride controller.
  DriverRideController get rideController => _sharedController;

  static AppState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppState>();
    assert(result != null, 'No AppState found in context');
    return result!;
  }

  static AppState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppState>();
  }

  @override
  bool updateShouldNotify(AppState oldWidget) => false;
}

/// Convenience extension to access app state from BuildContext.
extension AppStateExtension on BuildContext {
  AppState get appState => AppState.of(this);
  DriverRideController get rideController => _sharedController;
  RideRepository get rideRepository => _sharedRideRepo;
  ChatRepository get chatRepository => _sharedChatRepo;
}
