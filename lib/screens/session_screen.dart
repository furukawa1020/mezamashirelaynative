import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/group.dart';
import '../models/mission.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';

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
    final storage = Provider.of<StorageService>(context, listen: false);

    // 繝｡繝ｳ繝舌・諠・ｱ蜿門ｾ・
    final userNicknames = <String, String>{};
    for (final userId in _group!.memberIds) {
      // TODO: 繝ｦ繝ｼ繧ｶ繝ｼ諠・ｱ蜿門ｾ暦ｼ育樟迥ｶ縺ｯ莉ｮ螳溯｣・ｼ・
      userNicknames[userId] = '繝ｦ繝ｼ繧ｶ繝ｼ${userId.substring(0, 6)}';
    }

    final session = await sessionService.createSession(
      groupId: widget.groupId,
      missionId: widget.missionId,
      userIds: _group!.memberIds,
      userNicknames: userNicknames,
    );

    await sessionService.startSession(session.sessionId);

    if (!mounted) return;
    
    // 繧ｻ繝・す繝ｧ繝ｳ螳溯｡檎判髱｢縺ｸ驕ｷ遘ｻ
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
        title: const Text('繧ｻ繝・す繝ｧ繝ｳ髢句ｧ・),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _group == null || _mission == null
              ? const Center(child: Text('繝・・繧ｿ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 繧ｰ繝ｫ繝ｼ繝玲ュ蝣ｱ
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '繧ｰ繝ｫ繝ｼ繝・,
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
                                  Text('${_group!.memberIds.length}莠ｺ'),
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
                                        ? '繝ｬ繝ｼ繧ｹ繝｢繝ｼ繝・
                                        : '蜈ｨ蜩｡驕疲・繝｢繝ｼ繝・,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 繝溘ャ繧ｷ繝ｧ繝ｳ諠・ｱ
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '繝溘ャ繧ｷ繝ｧ繝ｳ',
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
                                  Text('${_mission!.steps.length}繧ｹ繝・ャ繝・),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 繝溘ャ繧ｷ繝ｧ繝ｳ繧ｹ繝・ャ繝嶺ｸ隕ｧ
                      const Text(
                        '繧ｹ繝・ャ繝・,
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

                      // 髢句ｧ九・繧ｿ繝ｳ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startSession,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text(
                            '繧ｻ繝・す繝ｧ繝ｳ髢句ｧ・,
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
        return '謇句虚遒ｺ隱・;
      case StepActionType.shake:
        return '繧ｷ繧ｧ繧､繧ｯ讀懷・';
      case StepActionType.ble:
        return 'BLE繧ｻ繝ｳ繧ｵ繝ｼ';
      case StepActionType.qr:
        return 'QR繧ｳ繝ｼ繝・;
      case StepActionType.gps:
        return 'GPS菴咲ｽｮ';
      case StepActionType.aiDetect:
        return 'AI讀懷・';
    }
  }
}

// 繧ｻ繝・す繝ｧ繝ｳ螳溯｡檎判髱｢
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
        appBar: AppBar(title: const Text('繧ｻ繝・す繝ｧ繝ｳ')),
        body: const Center(child: Text('繧ｻ繝・す繝ｧ繝ｳ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ')),
      );
    }

    final currentStep = session.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: const Text('繧ｻ繝・す繝ｧ繝ｳ螳溯｡御ｸｭ'),
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
            // 繝励Ο繧ｰ繝ｬ繧ｹ
            LinearProgressIndicator(
              value: session.progress,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${session.completedSteps} / ${session.totalSteps} 繧ｹ繝・ャ繝怜ｮ御ｺ・,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 迴ｾ蝨ｨ縺ｮ繧ｹ繝・ャ繝・
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
                        '縺ｮ鬆・分縺ｧ縺・,
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
                            '螳御ｺ・,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 繧ｹ繝・ャ繝嶺ｸ隕ｧ
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
                              '螳御ｺ・ ${_formatDuration(step.durationMs!)}',
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

            // 繧ｻ繝・す繝ｧ繝ｳ螳御ｺ・
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
                        '繧ｻ繝・す繝ｧ繝ｳ螳御ｺ・ｼ・,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (session.totalDurationMs != null)
                        Text(
                          '蜷郁ｨ域凾髢・ ${_formatDuration(session.totalDurationMs!)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text('繝帙・繝縺ｸ謌ｻ繧・),
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
        title: const Text('繧ｻ繝・す繝ｧ繝ｳ繧偵く繝｣繝ｳ繧ｻ繝ｫ'),
        content: const Text('譛ｬ蠖薙↓繧ｻ繝・す繝ｧ繝ｳ繧偵く繝｣繝ｳ繧ｻ繝ｫ縺励∪縺吶°・・),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('謌ｻ繧・),
          ),
          TextButton(
            onPressed: () {
              service.cancelSession();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
          ),
        ],
      ),
    );
  }
}
