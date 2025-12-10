// ミッションモデル
class Mission {
  final String missionId;
  final String userId;
  final String name;
  final String wakeTime; // "HH:MM"
  final List<MissionStep> steps;
  final DateTime createdAt;

  Mission({
    required this.missionId,
    required this.userId,
    required this.name,
    required this.wakeTime,
    required this.steps,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'mission_id': missionId,
    'user_id': userId,
    'name': name,
    'wake_time': wakeTime,
    'steps': steps.map((s) => s.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
    missionId: json['mission_id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    wakeTime: json['wake_time'] as String,
    steps:
        (json['steps'] as List)
            .map((s) => MissionStep.fromJson(s as Map<String, dynamic>))
            .toList(),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ミッションステップ
class MissionStep {
  final String stepId;
  final String label;
  final int order;
  final StepActionType actionType;
  final Map<String, dynamic> actionConfig;
  final String? bleEventType;

  MissionStep({
    required this.stepId,
    required this.label,
    required this.order,
    required this.actionType,
    required this.actionConfig,
    this.bleEventType,
  });

  Map<String, dynamic> toJson() => {
    'step_id': stepId,
    'label': label,
    'order': order,
    'action_type': actionType.name,
    'action_config': actionConfig,
    'ble_event_type': bleEventType,
  };

  factory MissionStep.fromJson(Map<String, dynamic> json) => MissionStep(
    stepId: json['step_id'] as String,
    label: json['label'] as String,
    order: json['order'] as int,
    actionType: StepActionType.values.byName(json['action_type'] as String),
    actionConfig: Map<String, dynamic>.from(json['action_config'] as Map),
    bleEventType: json['ble_event_type'] as String?,
  );
}

enum StepActionType {
  manual, // 手動タップ
  shake, // シェイク
  ble, // BLEセンサー
  qr, // QRコード
  gps, // GPS
  aiDetect, // AI物体検出
}
