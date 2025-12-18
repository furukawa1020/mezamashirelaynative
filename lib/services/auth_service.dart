import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'api_service.dart';

// 匿名認証サービス - API連携版
class AuthService extends ChangeNotifier {
  static const String _userKey = 'mz_user';
  static const String _deviceIdKey = 'mz_device_id';
  static const Uuid _uuid = Uuid();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // シングルトン
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AppUser? _currentUser;
  String? _deviceId;

  // 現在のユーザー取得
  AppUser? get currentUser => _currentUser;
  String? get deviceId => _deviceId;

  // デバイスIDを生成または取得
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString(_deviceIdKey);

    if (storedDeviceId != null) {
      return storedDeviceId;
    }

    // デバイス情報から一意なIDを生成
    String deviceIdentifier;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceIdentifier = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceIdentifier = iosInfo.identifierForVendor ?? _uuid.v4();
      } else {
        deviceIdentifier = _uuid.v4();
      }
    } catch (e) {
      deviceIdentifier = _uuid.v4();
    }

    await prefs.setString(_deviceIdKey, deviceIdentifier);
    return deviceIdentifier;
  }

  // 初期化（アプリ起動時に呼ぶ）- API同期付き
  Future<AppUser> initialize() async {
    // デバイスIDを取得
    _deviceId = await _getOrCreateDeviceId();

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

      // APIと同期
      await _syncWithApi();
    } else {
      // 新規ユーザー作成（完全匿名）
      _currentUser = AppUser(
        userId: _uuid.v4(),
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      await _saveUser(_currentUser!);

      // APIと同期
      await _syncWithApi();
    }

    return _currentUser!;
  }

  // APIと同期
  Future<void> _syncWithApi() async {
    if (_currentUser == null) return;

    try {
      final user = _currentUser!;
      await ApiService.syncUser(
        userId: user.userId,
        nickname: user.nickname ?? '',
        avatarUrl: user.avatarUrl,
        isAnonymous: user.nickname == null,
      );
    } catch (e) {
      print('Failed to sync user with API: $e');
    }
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

      // APIに更新を送信
      try {
        await ApiService.updateUser(
          userId: _currentUser!.userId,
          nickname: _currentUser!.nickname,
          avatarUrl: _currentUser!.avatarUrl,
        );
      } catch (e) {
        print('Failed to update user profile on API: $e');
      }

      notifyListeners();
    }

    // ユーザー情報を保存
    Future<void> _saveUser(AppUser user) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, _jsonEncode(user.toJson()));
    }

    // ユーザー情報取得（userId指定）
    Future<AppUser?> getUser(String userId) async {
      if (_currentUser?.userId == userId) {
        return _currentUser;
      }
    
    // StorageServiceからキャッシュを取得
    final storage = StorageService();
    final cachedUser = await storage.getCachedUserInfo(userId);
    if (cachedUser != null) {
      return cachedUser;
    }

    // キャッシュにない場合は、グループやセッションから推測して生成
    final generatedUser = AppUser(
      userId: userId,
      nickname: 'ユーザー${userId.substring(0, 6)}',
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    // 生成したユーザー情報をキャッシュに保存
    await storage.cacheUserInfo(generatedUser);

    return generatedUser;
  }

  // アカウントリセット
  Future<void> resetAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_deviceIdKey);
    _currentUser = null;
    _deviceId = null;
    notifyListeners();
  }

  // JSON処理
  Map<String, dynamic> _parseJson(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  String _jsonEncode(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  // 認証トークン生成
  String generateAuthToken() {
    if (_currentUser == null || _deviceId == null) {
      throw Exception('User or device not initialized');
    }
    return '${_currentUser!.userId}:$_deviceId:${DateTime.now().millisecondsSinceEpoch}';
  }
