import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group.dart';
import '../models/mission.dart';
import '../models/session.dart';

// 繝ｭ繝ｼ繧ｫ繝ｫ繧ｹ繝医Ξ繝ｼ繧ｸ繧ｵ繝ｼ繝薙せ・・haredPreferences wrapper・・
class StorageService {
  static const String _groupsKey = 'mz_groups';
  static const String _missionsKey = 'mz_missions';
  static const String _groupMembersKey = 'mz_group_members';
  static const String _sessionsKey = 'mz_sessions';

  // 繧ｷ繝ｳ繧ｰ繝ｫ繝医Φ
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // === 繧ｰ繝ｫ繝ｼ繝玲桃菴・===

  // 繧ｰ繝ｫ繝ｼ繝嶺ｽ懈・
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

    // 譌｢蟄倥げ繝ｫ繝ｼ繝怜叙蠕・
    final groups = await getGroups(ownerId);
    groups.add(group);

    // 菫晏ｭ・
    final groupsJson = groups.map((g) => g.toJson()).toList();
    await prefs.setString(_groupsKey, jsonEncode(groupsJson));

    return group;
  }

  // 諡帛ｾ・さ繝ｼ繝峨〒繧ｰ繝ｫ繝ｼ繝玲､懃ｴ｢
  Future<Group?> findGroupByInviteCode(String inviteCode) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsStr = prefs.getString(_groupsKey);
    if (groupsStr == null) return null;

    final List<dynamic> groupsJson = jsonDecode(groupsStr);
    final groups = groupsJson.map((j) => Group.fromJson(j)).toList();

    return groups.where((g) => g.inviteCode == inviteCode).firstOrNull;
  }

  // 繧ｰ繝ｫ繝ｼ繝励↓蜿ょ刈
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

  // 繝ｦ繝ｼ繧ｶ繝ｼ縺ｮ繧ｰ繝ｫ繝ｼ繝嶺ｸ隕ｧ蜿門ｾ・
  Future<List<Group>> getGroups(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsStr = prefs.getString(_groupsKey);
    if (groupsStr == null) return [];

    final List<dynamic> groupsJson = jsonDecode(groupsStr);
    final groups = groupsJson.map((j) => Group.fromJson(j)).toList();

    return groups.where((g) => g.memberIds.contains(userId)).toList();
  }

  // === 繝溘ャ繧ｷ繝ｧ繝ｳ謫堺ｽ・===

  // 繝溘ャ繧ｷ繝ｧ繝ｳ菴懈・
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

  // 繝ｦ繝ｼ繧ｶ繝ｼ縺ｮ繝溘ャ繧ｷ繝ｧ繝ｳ荳隕ｧ蜿門ｾ・
  Future<List<Mission>> getMissions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final missionsStr = prefs.getString(_missionsKey);
    if (missionsStr == null) return [];

    final List<dynamic> missionsJson = jsonDecode(missionsStr);
    final missions = missionsJson.map((j) => Mission.fromJson(j)).toList();

    return missions.where((m) => m.userId == userId).toList();
  }

  // 繝溘ャ繧ｷ繝ｧ繝ｳ蜿門ｾ・
  Future<Mission?> getMission(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final missionsStr = prefs.getString(_missionsKey);
    if (missionsStr == null) return null;

    final List<dynamic> missionsJson = jsonDecode(missionsStr);
    final missions = missionsJson.map((j) => Mission.fromJson(j)).toList();

    try {
      return missions.firstWhere((m) => m.missionId == missionId);
    } catch (e) {
      return null;
    }
  }

  // 繝溘ャ繧ｷ繝ｧ繝ｳ譖ｴ譁ｰ
  Future<void> updateMission(Mission mission) async {
    final prefs = await SharedPreferences.getInstance();
    final missionsStr = prefs.getString(_missionsKey);

    List<Mission> missions = [];
    if (missionsStr != null) {
      final List<dynamic> missionsJson = jsonDecode(missionsStr);
      missions = missionsJson.map((j) => Mission.fromJson(j)).toList();
    }

    final index = missions.indexWhere((m) => m.missionId == mission.missionId);
    if (index >= 0) {
      missions[index] = mission;
    } else {
      missions.add(mission);
    }

    final missionsJson = missions.map((m) => m.toJson()).toList();
    await prefs.setString(_missionsKey, jsonEncode(missionsJson));
  }

  // 繝溘ャ繧ｷ繝ｧ繝ｳ蜑企勁
  Future<void> deleteMission(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final missionsStr = prefs.getString(_missionsKey);
    if (missionsStr == null) return;

    final List<dynamic> missionsJson = jsonDecode(missionsStr);
    final missions = missionsJson.map((j) => Mission.fromJson(j)).toList();

    missions.removeWhere((m) => m.missionId == missionId);

    final updatedJson = missions.map((m) => m.toJson()).toList();
    await prefs.setString(_missionsKey, jsonEncode(updatedJson));
  }

  // === 繝ｦ繝ｼ繝・ぅ繝ｪ繝・ぅ ===

  // ID逕滓・
  String _generateId(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  // 6譯∵魚蠕・さ繝ｼ繝臥函謌・
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 邏帙ｉ繧上＠縺・枚蟄鈴勁螟・
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int seed = random;

    for (int i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      code += chars[seed % chars.length];
    }

    return code;
  }

  // === 繧ｻ繝・す繝ｧ繝ｳ謫堺ｽ・===

  // 繧ｻ繝・す繝ｧ繝ｳ菫晏ｭ・
  Future<void> saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();

    // 譌｢蟄倥そ繝・す繝ｧ繝ｳ繧呈峩譁ｰ縺ｾ縺溘・霑ｽ蜉
    final index = sessions.indexWhere((s) => s.sessionId == session.sessionId);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }

    final sessionsJson = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
  }

  // 繧ｻ繝・す繝ｧ繝ｳ蜿門ｾ・
  Future<Session?> getSession(String sessionId) async {
    final sessions = await getSessions();
    return sessions.firstWhere(
      (s) => s.sessionId == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
  }

  // 繧ｻ繝・す繝ｧ繝ｳ荳隕ｧ蜿門ｾ・
  Future<List<Session>> getSessions({String? groupId, int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsString = prefs.getString(_sessionsKey);

    if (sessionsString == null) return [];

    final sessionsList = jsonDecode(sessionsString) as List;
    var sessions =
        sessionsList
            .map((json) => Session.fromJson(json as Map<String, dynamic>))
            .toList();

    // 繧ｰ繝ｫ繝ｼ繝悠D縺ｧ繝輔ぅ繝ｫ繧ｿ繝ｼ
    if (groupId != null) {
      sessions = sessions.where((s) => s.groupId == groupId).toList();
    }

    // 菴懈・譌･譎る剄鬆・〒繧ｽ繝ｼ繝・
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 蛻ｶ髯・
    return sessions.take(limit).toList();
  }

  // 繧ｻ繝・す繝ｧ繝ｳ蜑企勁
  Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();

    sessions.removeWhere((s) => s.sessionId == sessionId);

    final sessionsJson = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
  }

  // 蜈ｨ繝・・繧ｿ繧ｯ繝ｪ繧｢・医ョ繝舌ャ繧ｰ逕ｨ・・
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

// Dart 2.x莠呈鋤逕ｨextension
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
