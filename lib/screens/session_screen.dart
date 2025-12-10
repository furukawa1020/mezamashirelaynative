import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/group.dart';
import '../models/mission.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class SessionScreen extends StatefulWidget {
  final String groupId;
  final String missionId;

  const SessionScreen({
    Key? key,
    required this.groupId,
    required this.missionId,
  }) : super(key: key);

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Group? _group;
  Mission? _mission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    final group = await storage.getGroup(widget.groupId);
    final mission = await storage.getMission(widget.missionId);

    setState(() {
      _group = group;
      _mission = mission;
      _isLoading = false;
    });
  }

  Future<void> _startSession() async {
    if (_group == null || _mission == null) return;

    final sessionService = Provider.of<SessionService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    // メンバー情報取得
    final userNicknames = <String, String>{};
    for (final userId in _group!.memberIds) {
      final user = await auth.getUser(userId);
      userNicknames[userId] = user?.displayName ?? 'ユーザー${userId.substring(0, 6)}';
    }

    final session = await sessionService.createSession(
      groupId: widget.groupId,
      missionId: widget.missionId,
      userIds: _group!.memberIds,
      userNicknames: userNicknames,
    );

    await sessionService.startSession(session.sessionId);

    if (!mounted) return;
    
    // セチE��ョン実行画面へ遷移
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionRunningScreen(
          sessionId: session.sessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('セチE��ョン開姁E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _group == null || _mission == null
              ? const Center(child: Text('チE�Eタが見つかりません'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // グループ情報
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'グルーチE,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _group!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.people, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${_group!.memberIds.length}人'),
                                  const SizedBox(width: 16),
                                  Icon(
                                    _group!.mode == GroupMode.race
                                        ? Icons.timer
                                        : Icons.check_circle,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _group!.mode == GroupMode.race
                                        ? 'レースモーチE
                                        : '全員達�EモーチE,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ミッション惁E��
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ミッション',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _mission!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_mission!.description != null) ...[
                                const SizedBox(height: 8),
                                Text(_mission!.description!),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.list_alt, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${_mission!.steps.length}スチE��チE),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ミッションスチE��プ一覧
                      const Text(
                        'スチE��チE,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _mission!.steps.length,
                          itemBuilder: (context, index) {
                            final step = _mission!.steps[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(step.name),
                                subtitle: Text(
                                  _getActionTypeLabel(step.actionType),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 開始�Eタン
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startSession,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text(
                            'セチE��ョン開姁E,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _getActionTypeLabel(StepActionType type) {
    switch (type) {
      case StepActionType.manual:
        return '手動確誁E;
      case StepActionType.shake:
        return 'シェイク検�E';
      case StepActionType.ble:
        return 'BLEセンサー';
      case StepActionType.qr:
        return 'QRコーチE;
      case StepActionType.gps:
        return 'GPS位置';
      case StepActionType.aiDetect:
        return 'AI検�E';
    }
  }
}

// セチE��ョン実行画面
class SessionRunningScreen extends StatelessWidget {
  final String sessionId;

  const SessionRunningScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionService = Provider.of<SessionService>(context);
    final session = sessionService.currentSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('セチE��ョン')),
        body: const Center(child: Text('セチE��ョンが見つかりません')),
      );
    }

    final currentStep = session.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: const Text('セチE��ョン実行中'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(context, sessionService),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // プログレス
            LinearProgressIndicator(
              value: session.progress,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${session.completedSteps} / ${session.totalSteps} スチE��プ完亁E,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 現在のスチE��チE
            if (currentStep != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        child: Text(
                          '${currentStep.stepOrder + 1}',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentStep.nickname ?? currentStep.userId,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'の頁E��でぁE,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      if (!currentStep.isCompleted)
                        ElevatedButton(
                          onPressed: () {
                            sessionService.completeStep(
                              stepId: currentStep.stepId,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            '完亁E,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // スチE��プ一覧
            Expanded(
              child: ListView.builder(
                itemCount: session.steps.length,
                itemBuilder: (context, index) {
                  final step = session.steps[index];
                  final isCurrent = step.stepId == currentStep?.stepId;
                  
                  return Card(
                    color: isCurrent ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: step.isCompleted
                            ? Colors.green
                            : isCurrent
                                ? Colors.blue
                                : Colors.grey,
                        child: Icon(
                          step.isCompleted
                              ? Icons.check
                              : isCurrent
                                  ? Icons.play_arrow
                                  : Icons.circle_outlined,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(step.nickname ?? step.userId),
                      subtitle: step.isCompleted && step.durationMs != null
                          ? Text(
                              '完亁E ${_formatDuration(step.durationMs!)}',
                            )
                          : null,
                      trailing: step.bleEventType != null
                          ? Chip(
                              label: Text(step.bleEventType!),
                              backgroundColor: Colors.green.shade100,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),

            // セチE��ョン完亁E
            if (session.status == SessionStatus.completed) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 64,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'セチE��ョン完亁E��E,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (session.totalDurationMs != null)
                        Text(
                          '合計時閁E ${_formatDuration(session.totalDurationMs!)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text('ホ�Eムへ戻めE),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showCancelDialog(BuildContext context, SessionService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('セチE��ョンをキャンセル'),
        content: const Text('本当にセチE��ョンをキャンセルしますか�E�E),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('戻めE),
          ),
          TextButton(
            onPressed: () {
              service.cancelSession();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}
