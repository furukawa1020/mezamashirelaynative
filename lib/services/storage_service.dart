import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group.dart';
import '../models/mission.dart';
import '../models/session.dart';

// ローカルストレージサービス（SharedPreferences wrapper）
class StorageService {
  static const String _groupsKey = 'mz_groups';
  static const String _missionsKey = 'mz_missions';
  static const String _groupMembersKey = 'mz_group_members';
  static const String _sessionsKey = 'mz_sessions';

  // シングルトン
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // === グループ操作 ===

  // グループ作成
  Future<Group> createGroup({
    required String name,
    required GroupMode mode,
    required String ownerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final group = Group(
      groupId: _generateId('g'),
      name: name,
      inviteCode: _generateInviteCode(),
      mode: mode,
      ownerId: ownerId,
      memberIds: [ownerId],
      createdAt: DateTime.now(),
    );

    // 既存グループ取得
    final groups = await getGroups(ownerId);
    groups.add(group);

    // 保存
    final groupsJson = groups.map((g) => g.toJson()).toList();
    await prefs.setString(_groupsKey, jsonEncode(groupsJson));

    return group;
  }

  // 招待コードでグループ検索
  Future<Group?> findGroupByInviteCode(String inviteCode) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsStr = prefs.getString(_groupsKey);
    if (groupsStr == null) return null;

    final List<dynamic> groupsJson = jsonDecode(groupsStr);
    final groups = groupsJson.map((j) => Group.fromJson(j)).toList();

    return groups.where((g) => g.inviteCode == inviteCode).firstOrNull;
  }

  // グループに参加
  Future<void> joinGroup(String groupId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsStr = prefs.getString(_groupsKey);
    if (groupsStr == null) return;

    final List<dynamic> groupsJson = jsonDecode(groupsStr);
    final groups = groupsJson.map((j) => Group.fromJson(j)).toList();

    final groupIndex = groups.indexWhere((g) => g.groupId == groupId);
    if (groupIndex == -1) return;

    final group = groups[groupIndex];
    if (!group.memberIds.contains(userId)) {
      final updatedGroup = Group(
        groupId: group.groupId,
        name: group.name,
        inviteCode: group.inviteCode,
        mode: group.mode,
        ownerId: group.ownerId,
        memberIds: [...group.memberIds, userId],
        createdAt: group.createdAt,
      );
      groups[groupIndex] = updatedGroup;

      final groupsJsonUpdated = groups.map((g) => g.toJson()).toList();
      await prefs.setString(_groupsKey, jsonEncode(groupsJsonUpdated));
    }
  }

  // ユーザーのグループ一覧取得
  Future<List<Group>> getGroups(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsStr = prefs.getString(_groupsKey);
    if (groupsStr == null) return [];

    final List<dynamic> groupsJson = jsonDecode(groupsStr);
    final groups = groupsJson.map((j) => Group.fromJson(j)).toList();

    return groups.where((g) => g.memberIds.contains(userId)).toList();
  }

  // === ミッション操作 ===

  // ミッション作成
  Future<Mission> createMission({
    required String userId,
    required String name,
    required String wakeTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final mission = Mission(
      missionId: _generateId('m'),
      userId: userId,
      name: name,
      wakeTime: wakeTime,
      steps: [],
      createdAt: DateTime.now(),
    );

    final missions = await getMissions(userId);
    missions.add(mission);

    final missionsJson = missions.map((m) => m.toJson()).toList();
    await prefs.setString(_missionsKey, jsonEncode(missionsJson));

    return mission;
  }

  // ユーザーのミッション一覧取得
  Future<List<Mission>> getMissions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final missionsStr = prefs.getString(_missionsKey);
    if (missionsStr == null) return [];

    final List<dynamic> missionsJson = jsonDecode(missionsStr);
    final missions = missionsJson.map((j) => Mission.fromJson(j)).toList();

    return missions.where((m) => m.userId == userId).toList();
  }

  // === ユーティリティ ===

  // ID生成
  String _generateId(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  // 6桁招待コード生成
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 紛らわしい文字除外
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int seed = random;

    for (int i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      code += chars[seed % chars.length];
    }

    return code;
  }

  // === セッション操作 ===

  // セッション保存
  Future<void> saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();

    // 既存セッションを更新または追加
    final index = sessions.indexWhere((s) => s.sessionId == session.sessionId);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }

    final sessionsJson = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
  }

  // セッション取得
  Future<Session?> getSession(String sessionId) async {
    final sessions = await getSessions();
    return sessions.firstWhere(
      (s) => s.sessionId == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
  }

  // セッション一覧取得
  Future<List<Session>> getSessions({
    String? groupId,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsString = prefs.getString(_sessionsKey);

    if (sessionsString == null) return [];

    final sessionsList = jsonDecode(sessionsString) as List;
    var sessions = sessionsList
        .map((json) => Session.fromJson(json as Map<String, dynamic>))
        .toList();

    // グループIDでフィルター
    if (groupId != null) {
      sessions = sessions.where((s) => s.groupId == groupId).toList();
    }

    // 作成日時降順でソート
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 制限
    return sessions.take(limit).toList();
  }

  // セッション削除
  Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();

    sessions.removeWhere((s) => s.sessionId == sessionId);

    final sessionsJson = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
  }

  // 全データクリア（デバッグ用）
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

// Dart 2.x互換用extension
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
