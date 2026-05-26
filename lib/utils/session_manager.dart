import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const int sessionTimeoutMinutes = 15;

  static Future<void> saveLoginSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);

    await prefs.setInt(
      'lastActiveTime',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      'lastActiveTime',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn =
        prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) return false;

    final lastActive =
        prefs.getInt('lastActiveTime') ?? 0;

    final now =
        DateTime.now().millisecondsSinceEpoch;

    final differenceMinutes =
        (now - lastActive) ~/ (1000 * 60);

    return differenceMinutes <= sessionTimeoutMinutes;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}