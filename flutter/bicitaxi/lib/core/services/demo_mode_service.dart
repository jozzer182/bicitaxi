import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage demo mode state across the app.
/// When demo mode is enabled, mockup data is shown.
/// When disabled (default), screens show real Firebase data.
class DemoModeService {
  // Singleton pattern
  static final DemoModeService _instance = DemoModeService._internal();
  factory DemoModeService() => _instance;
  DemoModeService._internal();

  static const String _prefsKey = 'demo_mode_enabled';

  /// ValueNotifier for reactive state management.
  /// true = demo mode enabled (show mockup data)
  /// false = demo mode disabled (show real data) - DEFAULT
  final ValueNotifier<bool> isDemoMode = ValueNotifier<bool>(false);

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Initialize the service and load persisted state.
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      isDemoMode.value = prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      // If SharedPreferences fails, default to demo mode disabled
      isDemoMode.value = false;
    }
    _initialized = true;
  }

  /// Set demo mode state and persist it.
  Future<void> setDemoMode(bool value) async {
    isDemoMode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (e) {
      // Silently fail persistence, state is still updated in memory
      debugPrint('Failed to persist demo mode setting: $e');
    }
  }

  /// Toggle demo mode state.
  Future<void> toggle() async {
    await setDemoMode(!isDemoMode.value);
  }
}
