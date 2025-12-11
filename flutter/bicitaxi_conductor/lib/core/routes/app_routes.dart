import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/profile/presentation/driver_profile_screen.dart';
import '../../features/rides/presentation/driver_active_ride_screen.dart';
import '../../features/rides/presentation/driver_earnings_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/payment_methods_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../providers/app_state.dart';

/// Route names for the Bici Taxi Conductor app.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String homeShell = '/homeShell';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String activeRide = '/activeRide';
  static const String earnings = '/earnings';
  static const String chat = '/chat';
  static const String paymentMethods = '/paymentMethods';
  static const String about = '/about';
  static const String editProfile = '/editProfile';
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
      case AppRoutes.register:
        return _buildRoute(const RegisterScreen(), settings);
      case AppRoutes.homeShell:
        return _buildRoute(const HomeShell(), settings);
      case AppRoutes.map:
        return _buildRoute(const MapScreen(), settings);
      case AppRoutes.profile:
        return _buildRoute(const DriverProfileScreen(), settings);
      case AppRoutes.activeRide:
        return _buildRoute(const DriverActiveRideScreen(), settings);
      case AppRoutes.earnings:
        return _buildRoute(const DriverEarningsScreen(), settings);
      case AppRoutes.chat:
        final args = settings.arguments as ChatRouteArgs;
        return _buildRoute(
          Builder(
            builder: (context) => ChatScreen(
              rideId: args.rideId,
              chatRepo: context.chatRepository,
              currentUserId: 'driver-demo',
              isClientApp: false,
              participantName: args.participantName,
            ),
          ),
          settings,
        );
      case AppRoutes.about:
        return _buildRoute(const AboutScreen(), settings);
      case AppRoutes.paymentMethods:
        return _buildRoute(const PaymentMethodsScreen(), settings);
      case AppRoutes.editProfile:
        return _buildRoute(const EditProfileScreen(), settings);
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
