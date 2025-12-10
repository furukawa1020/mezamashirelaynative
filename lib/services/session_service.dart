import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/group.dart';
import '../models/mission.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'ble_service.dart';

// セッションサービス
class SessionService extends ChangeNotifier {
  final StorageService _storageService;
  final BLEService _bleService;

  Session? _currentSession;
  Timer? _sessionTimer;
  DateTime? _stepStartTime;

  Session? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession?.status == SessionStatus.active;

  SessionService(this._storageService, this._bleService) {
    _initBLEListener();
  }

  void _initBLEListener() {
    _bleService.eventStream.listen((event) {
      if (_currentSession != null && 
          _currentSession!.status == SessionStatus.active) {
        _handleBLEEvent(event.eventType, event.tagId);
      }
    });
  }

  // セッション作成
  Future<Session> createSession({
    required String groupId,
    required String missionId,
    required List<String> userIds,
    required Map<String, String> userNicknames,
  }) async {
    final session = Session.create(
      groupId: groupId,
      missionId: missionId,
      userIds: userIds,
      userNicknames: userNicknames,
    );

    await _storageService.saveSession(session);
    return session;
  }

  // セッション開始
  Future<void> startSession(String sessionId) async {
    final session = await _storageService.getSession(sessionId);
    if (session == null) {
      throw Exception('Session not found');
    }

    _currentSession = session.copyWith(
      status: SessionStatus.active,
      startedAt: DateTime.now(),
    );
    _stepStartTime = DateTime.now();

    await _storageService.saveSession(_currentSession!);
    notifyListeners();
  }

  // スチE��プ完亁E
  Future<void> completeStep({
    required String stepId,
    String? bleEventType,
  }) async {
    if (_currentSession == null) return;

    final stepIndex = _currentSession!.steps.indexWhere((s) => s.stepId == stepId);
    if (stepIndex == -1) return;

    final now = DateTime.now();
    final duration = _stepStartTime != null
        ? now.difference(_stepStartTime!).inMilliseconds
        : 0;

    final updatedSteps = List<SessionStep>.from(_currentSession!.steps);
    updatedSteps[stepIndex] = updatedSteps[stepIndex].copyWith(
      completedAt: now,
      durationMs: duration,
      bleEventType: bleEventType,
    );

    _currentSession = _currentSession!.copyWith(steps: updatedSteps);

    // 全スチE��プ完亁E��ェチE��
    if (_currentSession!.completedSteps == _currentSession!.totalSteps) {
      await _completeSession();
    } else {
      _stepStartTime = DateTime.now();
      await _storageService.saveSession(_currentSession!);
      notifyListeners();
    }
  }

  // セチE��ョン完亁E
  Future<void> _completeSession() async {
    if (_currentSession == null) return;

    final totalDuration = _currentSession!.startedAt != null
        ? DateTime.now().difference(_currentSession!.startedAt!).inMilliseconds
        : 0;

    _currentSession = _currentSession!.copyWith(
      status: SessionStatus.completed,
      completedAt: DateTime.now(),
      totalDurationMs: totalDuration,
    );

    await _storageService.saveSession(_currentSession!);
    _sessionTimer?.cancel();
    _stepStartTime = null;
    notifyListeners();
  }

  // セチE��ョンキャンセル
  Future<void> cancelSession() async {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      status: SessionStatus.failed,
      completedAt: DateTime.now(),
    );

    await _storageService.saveSession(_currentSession!);
    _sessionTimer?.cancel();
    _stepStartTime = null;
    _currentSession = null;
    notifyListeners();
  }

  // BLEイベント�E琁E
  void _handleBLEEvent(String eventType, String tagId) {
    if (_currentSession == null || !hasActiveSession) return;

    final currentStep = _currentSession!.currentStep;
    if (currentStep == null) return;

    // イベントタイプに応じて自動的にスチE��プ完亁E
    if (_shouldCompleteStep(eventType)) {
      completeStep(
        stepId: currentStep.stepId,
        bleEventType: eventType,
      );
    }
  }

  bool _shouldCompleteStep(String eventType) {
    // OPEN, LIFT, SHAKE イベントでスチE��プ完亁E
    return ['OPEN', 'LIFT', 'SHAKE'].contains(eventType);
  }

  // セチE��ョン履歴取征E
  Future<List<Session>> getSessionHistory({
    String? groupId,
    int limit = 20,
  }) async {
    return await _storageService.getSessions(
      groupId: groupId,
      limit: limit,
    );
  }

  // セッション詳細取得
  Future<Session?> getSession(String sessionId) async {
    return await _storageService.getSession(sessionId);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
