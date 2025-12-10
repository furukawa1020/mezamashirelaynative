import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

// GRAVITY蠑丞諺蜷崎ｪ崎ｨｼ繧ｵ繝ｼ繝薙せ
class AuthService {
  static const String _userKey = 'mz_user';
  static const Uuid _uuid = Uuid();

  // 繧ｷ繝ｳ繧ｰ繝ｫ繝医Φ
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AppUser? _currentUser;

  // 迴ｾ蝨ｨ縺ｮ繝ｦ繝ｼ繧ｶ繝ｼ蜿門ｾ・
  AppUser? get currentUser => _currentUser;

  // 蛻晄悄蛹厄ｼ医い繝励Μ襍ｷ蜍墓凾縺ｫ蜻ｼ縺ｶ・・
  Future<AppUser> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      // 譌｢蟄倥Θ繝ｼ繧ｶ繝ｼ隱ｭ縺ｿ霎ｼ縺ｿ
      _currentUser = AppUser.fromJson(_parseJson(userJson));
      // 譛邨ゅい繧ｯ繝・ぅ繝匁凾蛻ｻ譖ｴ譁ｰ
      _currentUser = AppUser(
        userId: _currentUser!.userId,
        nickname: _currentUser!.nickname,
        avatarUrl: _currentUser!.avatarUrl,
        createdAt: _currentUser!.createdAt,
        lastActiveAt: DateTime.now(),
      );
      await _saveUser(_currentUser!);
    } else {
      // 譁ｰ隕上Θ繝ｼ繧ｶ繝ｼ菴懈・・亥諺蜷搾ｼ・
      _currentUser = AppUser(
        userId: _uuid.v4(),
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      await _saveUser(_currentUser!);
    }

    return _currentUser!;
  }

  // 繝励Ο繝輔ぅ繝ｼ繝ｫ譖ｴ譁ｰ
  Future<void> updateProfile({String? nickname, String? avatarUrl}) async {
    if (_currentUser == null) return;

    _currentUser = AppUser(
      userId: _currentUser!.userId,
      nickname: nickname ?? _currentUser!.nickname,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      createdAt: _currentUser!.createdAt,
      lastActiveAt: DateTime.now(),
    );

    await _saveUser(_currentUser!);
  }

  // 繝ｦ繝ｼ繧ｶ繝ｼ繝・・繧ｿ菫晏ｭ・
  Future<void> _saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, _jsonEncode(user.toJson()));
  }

  // 繧｢繧ｫ繧ｦ繝ｳ繝医Μ繧ｻ繝・ヨ・医ョ繝舌ャ繧ｰ逕ｨ・・
  Future<void> resetAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUser = null;
  }

  // JSON蜃ｦ逅・
  Map<String, dynamic> _parseJson(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  String _jsonEncode(Map<String, dynamic> map) {
    return jsonEncode(map);
  }
}
