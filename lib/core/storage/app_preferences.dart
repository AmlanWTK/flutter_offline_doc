import 'package:hive_flutter/hive_flutter.dart';

class AppPreferences {
  static const String _boxName = 'preferences';
  static const String _onboardingKey = 'onboarding_complete';

  static Future<void> initialize() async {
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  bool get hasCompletedOnboarding =>
      _box.get(_onboardingKey, defaultValue: false) as bool;

  Future<void> setOnboardingComplete() async {
    await _box.put(_onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    await _box.put(_onboardingKey, false);
  }
}
