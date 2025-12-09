import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/profile/presentation/client_profile_screen.dart';
import '../../features/rides/presentation/client_active_ride_screen.dart';
import '../../features/rides/presentation/client_history_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/payment_methods_screen.dart';
import '../providers/app_state.dart';

/// Route names for the Bici Taxi client app.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String homeShell = '/homeShell';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String activeRide = '/activeRide';
  static const String history = '/history';
  static const String chat = '/chat';
  static const String paymentMethods = '/paymentMethods';
}

/// Arguments for the chat route.
class ChatRouteArgs {
  const ChatRouteArgs({required this.rideId, this.participantName});
  final String rideId;
  final String? participantName;
}

/// Router configuration for the app.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);
      case AppRoutes.homeShell:
        return _buildRoute(const HomeShell(), settings);
      case AppRoutes.map:
        return _buildRoute(const MapScreen(), settings);
      case AppRoutes.profile:
        return _buildRoute(const ClientProfileScreen(), settings);
      case AppRoutes.activeRide:
        return _buildRoute(const ClientActiveRideScreen(), settings);
      case AppRoutes.history:
        return _buildRoute(const ClientHistoryScreen(), settings);
      case AppRoutes.chat:
        final args = settings.arguments as ChatRouteArgs;
        return _buildRoute(
          Builder(
            builder: (context) => ChatScreen(
              rideId: args.rideId,
              chatRepo: context.chatRepository,
              currentUserId: 'client-demo',
              isClientApp: true,
              participantName: args.participantName,
            ),
          ),
          settings,
        );
      case AppRoutes.paymentMethods:
        return _buildRoute(const PaymentMethodsScreen(), settings);
      default:
        return _buildRoute(const LoginScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
