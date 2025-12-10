import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

// GRAVITY式匿名認証サービス
class AuthService {
  static const String _userKey = 'mz_user';
  static const Uuid _uuid = Uuid();

  // シングルトン
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AppUser? _currentUser;

  // 現在のユーザー取得
  AppUser? get currentUser => _currentUser;

  // 初期化（アプリ起動時に呼ぶ）
  Future<AppUser> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      // 既存ユーザー読み込み
      _currentUser = AppUser.fromJson(_parseJson(userJson));
      // 最終アクティブ時刻更新
      _currentUser = AppUser(
        userId: _currentUser!.userId,
        nickname: _currentUser!.nickname,
        avatarUrl: _currentUser!.avatarUrl,
        createdAt: _currentUser!.createdAt,
        lastActiveAt: DateTime.now(),
      );
      await _saveUser(_currentUser!);
    } else {
      // 新規ユーザー作成（匿名）
      _currentUser = AppUser(
        userId: _uuid.v4(),
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      await _saveUser(_currentUser!);
    }

    return _currentUser!;
  }

  // プロフィール更新
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

  // ユーザーデータ保存
  Future<void> _saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, _jsonEncode(user.toJson()));
  }

  // アカウントリセット（デバッグ用）
  Future<void> resetAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUser = null;
  }

  // JSON処理
  Map<String, dynamic> _parseJson(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  String _jsonEncode(Map<String, dynamic> map) {
    return jsonEncode(map);
  }
}
