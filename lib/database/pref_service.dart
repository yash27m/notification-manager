import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  PrefService._();
  static final instance = PrefService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Onboarding ──

  static const _keyOnboardingDone = 'onboarding_done';

  bool get isOnboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) async {
    await _prefs.setBool(_keyOnboardingDone, value);
  }

  // ── Add more keys below as needed ──
}