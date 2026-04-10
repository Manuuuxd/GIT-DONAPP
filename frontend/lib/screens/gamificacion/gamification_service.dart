import 'package:shared_preferences/shared_preferences.dart';

class Gamification {
  static const _kXp = 'gm_xp';
  static const _kStreak = 'gm_streak';
  static const _kBadges = 'gm_badges'; // csv simple

  static Future<int> xp() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kXp) ?? 0;
  }

  static Future<void> addXp(int delta) async {
    final p = await SharedPreferences.getInstance();
    final v = (p.getInt(_kXp) ?? 0) + delta;
    await p.setInt(_kXp, v);
  }

  static Future<int> streak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kStreak) ?? 0;
  }

  static Future<void> bumpStreak() async {
    final p = await SharedPreferences.getInstance();
    final v = (p.getInt(_kStreak) ?? 0) + 1;
    await p.setInt(_kStreak, v);
  }

  static Future<List<String>> badges() async {
    final p = await SharedPreferences.getInstance();
    final csv = p.getString(_kBadges) ?? '';
    return csv.isEmpty ? [] : csv.split(',');
  }

  static Future<void> addBadge(String badge) async {
    final p = await SharedPreferences.getInstance();
    final list = await badges();
    if (!list.contains(badge)) list.add(badge);
    await p.setString(_kBadges, list.join(','));
  }
}