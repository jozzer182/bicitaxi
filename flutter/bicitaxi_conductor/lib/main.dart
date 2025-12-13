import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/routes/app_routes.dart';
import 'core/providers/app_state.dart';
import 'core/services/demo_mode_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize demo mode service
  await DemoModeService().init();

  // Set system UI overlay style for light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xCCFFFFFF), // White semi-transparent
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const BiciTaxiConductorApp());
}

/// Main application widget for Bici Taxi Conductor app.
class BiciTaxiConductorApp extends StatelessWidget {
  const BiciTaxiConductorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap with AppState to provide repository and controllers
    // TODO: Swap InMemoryRideRepository for Firebase implementation and proper DI.
    return AppState(
      child: LiquidThemeProvider(
        theme: LiquidTheme(
          primaryColor: AppColors.driverAccent,
          borderRadius: 24.0,
          defaultPadding: const EdgeInsets.all(16),
          defaultMargin: const EdgeInsets.all(8),
        ),
        child: MaterialApp(
          title: 'Bici Taxi Conductor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: FirebaseAuth.instance.currentUser != null 
              ? AppRoutes.homeShell 
              : AppRoutes.login,

          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            // Apply responsive constraints and ensure proper text scaling
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                // Limit text scale factor for accessibility while maintaining design
                textScaler: TextScaler.linear(
                  MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
                ),
              ),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarColor: Color(0xDDFFFFFF), // White 87% opacity
                  statusBarIconBrightness: Brightness.dark,
                  systemNavigationBarColor: Colors.white,
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
                child: _AppBackground(child: child ?? const SizedBox.shrink()),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Background wrapper with gradient for the entire app.
class _AppBackground extends StatelessWidget {
  const _AppBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Light transparent background - map shows through
    return Container(color: Colors.transparent, child: child);
  }
}
