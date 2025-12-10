import 'package:uuid/uuid.dart';

// セッション状態
enum SessionStatus {
  waiting, // 待機中
  active, // 実行中
  completed, // 完了
  failed, // 失敗
}

// セッションステップ
class SessionStep {
  final String stepId;
  final int stepOrder;
  final String userId;
  final String? nickname;
  final DateTime? completedAt;
  final int? durationMs;
  final String? bleEventType; // OPEN, LIFT, SHAKE, CLOSE等

  SessionStep({
    required this.stepId,
    required this.stepOrder,
    required this.userId,
    this.nickname,
    this.completedAt,
    this.durationMs,
    this.bleEventType,
  });

  bool get isCompleted => completedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'stepOrder': stepOrder,
      'userId': userId,
      'nickname': nickname,
      'completedAt': completedAt?.toIso8601String(),
      'durationMs': durationMs,
      'bleEventType': bleEventType,
    };
  }

  factory SessionStep.fromJson(Map<String, dynamic> json) {
    return SessionStep(
      stepId: json['stepId'] as String,
      stepOrder: json['stepOrder'] as int,
      userId: json['userId'] as String,
      nickname: json['nickname'] as String?,
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      durationMs: json['durationMs'] as int?,
      bleEventType: json['bleEventType'] as String?,
    );
  }

  SessionStep copyWith({
    String? stepId,
    int? stepOrder,
    String? userId,
    String? nickname,
    DateTime? completedAt,
    int? durationMs,
    String? bleEventType,
  }) {
    return SessionStep(
      stepId: stepId ?? this.stepId,
      stepOrder: stepOrder ?? this.stepOrder,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      completedAt: completedAt ?? this.completedAt,
      durationMs: durationMs ?? this.durationMs,
      bleEventType: bleEventType ?? this.bleEventType,
    );
  }
}

// セッション
class Session {
  final String sessionId;
  final String groupId;
  final String missionId;
  final SessionStatus status;
  final List<SessionStep> steps;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? totalDurationMs;

  Session({
    required this.sessionId,
    required this.groupId,
    required this.missionId,
    required this.status,
    required this.steps,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.totalDurationMs,
  });

  factory Session.create({
    required String groupId,
    required String missionId,
    required List<String> userIds,
    required Map<String, String> userNicknames,
  }) {
    final uuid = const Uuid();
    final steps =
        userIds.asMap().entries.map((entry) {
          return SessionStep(
            stepId: uuid.v4(),
            stepOrder: entry.key,
            userId: entry.value,
            nickname: userNicknames[entry.value],
          );
        }).toList();

    return Session(
      sessionId: uuid.v4(),
      groupId: groupId,
      missionId: missionId,
      status: SessionStatus.waiting,
      steps: steps,
      createdAt: DateTime.now(),
    );
  }

  int get completedSteps => steps.where((s) => s.isCompleted).length;
  int get totalSteps => steps.length;
  double get progress => totalSteps > 0 ? completedSteps / totalSteps : 0;

  SessionStep? get currentStep {
    return steps.firstWhere((s) => !s.isCompleted, orElse: () => steps.last);
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'groupId': groupId,
      'missionId': missionId,
      'status': status.name,
      'steps': steps.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalDurationMs': totalDurationMs,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['sessionId'] as String,
      groupId: json['groupId'] as String,
      missionId: json['missionId'] as String,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.waiting,
      ),
      steps:
          (json['steps'] as List)
              .map((s) => SessionStep.fromJson(s as Map<String, dynamic>))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt:
          json['startedAt'] != null
              ? DateTime.parse(json['startedAt'] as String)
              : null,
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      totalDurationMs: json['totalDurationMs'] as int?,
    );
  }

  Session copyWith({
    String? sessionId,
    String? groupId,
    String? missionId,
    SessionStatus? status,
    List<SessionStep>? steps,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? totalDurationMs,
  }) {
    return Session(
      sessionId: sessionId ?? this.sessionId,
      groupId: groupId ?? this.groupId,
      missionId: missionId ?? this.missionId,
      status: status ?? this.status,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
    );
  }
}
