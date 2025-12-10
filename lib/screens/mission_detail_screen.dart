import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mission.dart';
import '../services/storage_service.dart';

class MissionDetailScreen extends StatefulWidget {
  final String missionId;

  const MissionDetailScreen({Key? key, required this.missionId})
    : super(key: key);

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  Mission? _mission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  Future<void> _loadMission() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final mission = await storage.getMission(widget.missionId);

    setState(() {
      _mission = mission;
      _isLoading = false;
    });
  }

  Future<void> _addStep() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddStepDialog(),
    );

    if (result == null || _mission == null) return;

    final newStep = MissionStep(
      stepId: 'step_${DateTime.now().millisecondsSinceEpoch}',
      order: _mission!.steps.length,
      name: result['name'] as String,
      actionType: result['actionType'] as StepActionType,
      description: result['description'] as String?,
    );

    final updatedMission = Mission(
      missionId: _mission!.missionId,
      name: _mission!.name,
      description: _mission!.description,
      steps: [..._mission!.steps, newStep],
      createdAt: _mission!.createdAt,
    );

    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.updateMission(updatedMission);

    setState(() {
      _mission = updatedMission;
    });
  }

  Future<void> _editStep(MissionStep step) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddStepDialog(step: step),
    );

    if (result == null || _mission == null) return;

    final updatedSteps =
        _mission!.steps.map((s) {
          if (s.stepId == step.stepId) {
            return MissionStep(
              stepId: s.stepId,
              order: s.order,
              name: result['name'] as String,
              actionType: result['actionType'] as StepActionType,
              description: result['description'] as String?,
            );
          }
          return s;
        }).toList();

    final updatedMission = Mission(
      missionId: _mission!.missionId,
      name: _mission!.name,
      description: _mission!.description,
      steps: updatedSteps,
      createdAt: _mission!.createdAt,
    );

    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.updateMission(updatedMission);

    setState(() {
      _mission = updatedMission;
    });
  }

  Future<void> _deleteStep(MissionStep step) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('繧ｹ繝・ャ繝励ｒ蜑企勁'),
            content: Text('縲・{step.name}縲阪ｒ蜑企勁縺励∪縺吶°・・),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('蜑企勁'),
              ),
            ],
          ),
    );

    if (confirmed != true || _mission == null) return;

    final updatedSteps =
        _mission!.steps.where((s) => s.stepId != step.stepId).toList();

    // 繧ｹ繝・ャ繝励・鬆・ｺ上ｒ蜀崎ｨｭ螳・
    for (int i = 0; i < updatedSteps.length; i++) {
      updatedSteps[i] = MissionStep(
        stepId: updatedSteps[i].stepId,
        order: i,
        name: updatedSteps[i].name,
        actionType: updatedSteps[i].actionType,
        description: updatedSteps[i].description,
      );
    }

    final updatedMission = Mission(
      missionId: _mission!.missionId,
      name: _mission!.name,
      description: _mission!.description,
      steps: updatedSteps,
      createdAt: _mission!.createdAt,
    );

    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.updateMission(updatedMission);

    setState(() {
      _mission = updatedMission;
    });
  }

  Future<void> _reorderSteps(int oldIndex, int newIndex) async {
    if (_mission == null) return;

    final steps = List<MissionStep>.from(_mission!.steps);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final step = steps.removeAt(oldIndex);
    steps.insert(newIndex, step);

    // 鬆・ｺ上ｒ譖ｴ譁ｰ
    for (int i = 0; i < steps.length; i++) {
      steps[i] = MissionStep(
        stepId: steps[i].stepId,
        order: i,
        name: steps[i].name,
        actionType: steps[i].actionType,
        description: steps[i].description,
      );
    }

    final updatedMission = Mission(
      missionId: _mission!.missionId,
      name: _mission!.name,
      description: _mission!.description,
      steps: steps,
      createdAt: _mission!.createdAt,
    );

    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.updateMission(updatedMission);

    setState(() {
      _mission = updatedMission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ隧ｳ邏ｰ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editMission(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mission == null
              ? const Center(child: Text('繝溘ャ繧ｷ繝ｧ繝ｳ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ'))
              : Column(
                children: [
                  // 繝溘ャ繧ｷ繝ｧ繝ｳ諠・ｱ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mission!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_mission!.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _mission!.description!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                        const SizedBox(height: 8),
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

                  // 繧ｹ繝・ャ繝励Μ繧ｹ繝・
                  Expanded(
                    child:
                        _mission!.steps.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '繧ｹ繝・ャ繝励′縺ゅｊ縺ｾ縺帙ｓ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _addStep,
                                    icon: const Icon(Icons.add),
                                    label: const Text('譛蛻昴・繧ｹ繝・ャ繝励ｒ霑ｽ蜉'),
                                  ),
                                ],
                              ),
                            )
                            : ReorderableListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _mission!.steps.length,
                              onReorder: _reorderSteps,
                              itemBuilder: (context, index) {
                                final step = _mission!.steps[index];
                                return Card(
                                  key: ValueKey(step.stepId),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(step.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getActionTypeLabel(step.actionType),
                                        ),
                                        if (step.description != null)
                                          Text(step.description!),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editStep(step),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deleteStep(step),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton:
          _mission != null
              ? FloatingActionButton(
                onPressed: _addStep,
                child: const Icon(Icons.add),
              )
              : null,
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

  Future<void> _editMission() async {
    if (_mission == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditMissionDialog(mission: _mission!),
    );

    if (result == null) return;

    final updatedMission = Mission(
      missionId: _mission!.missionId,
      name: result['name']!,
      description: result['description'],
      steps: _mission!.steps,
      createdAt: _mission!.createdAt,
    );

    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.updateMission(updatedMission);

    setState(() {
      _mission = updatedMission;
    });
  }
}

// 繧ｹ繝・ャ繝苓ｿｽ蜉/邱ｨ髮・ム繧､繧｢繝ｭ繧ｰ
class _AddStepDialog extends StatefulWidget {
  final MissionStep? step;

  const _AddStepDialog({this.step});

  @override
  State<_AddStepDialog> createState() => _AddStepDialogState();
}

class _AddStepDialogState extends State<_AddStepDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late StepActionType _actionType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.step?.name);
    _descriptionController = TextEditingController(
      text: widget.step?.description,
    );
    _actionType = widget.step?.actionType ?? StepActionType.manual;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.step == null ? '繧ｹ繝・ャ繝励ｒ霑ｽ蜉' : '繧ｹ繝・ャ繝励ｒ邱ｨ髮・),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '繧ｹ繝・ャ繝怜錐',
                hintText: '萓・ 繧｢繝ｩ繝ｼ繝繧呈ｭ｢繧√ｋ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StepActionType>(
              value: _actionType,
              decoration: const InputDecoration(labelText: '繧｢繧ｯ繧ｷ繝ｧ繝ｳ繧ｿ繧､繝・),
              items:
                  StepActionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getActionTypeLabel(type)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _actionType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '隱ｬ譏趣ｼ井ｻｻ諢擾ｼ・,
                hintText: '萓・ XIAO繧ｻ繝ｳ繧ｵ繝ｼ縺ｧ繧ｷ繧ｧ繧､繧ｯ繧呈､懷・',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('繧ｹ繝・ャ繝怜錐繧貞・蜉帙＠縺ｦ縺上□縺輔＞')));
              return;
            }

            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'actionType': _actionType,
              'description':
                  _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
            });
          },
          child: Text(widget.step == null ? '霑ｽ蜉' : '譖ｴ譁ｰ'),
        ),
      ],
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

// 繝溘ャ繧ｷ繝ｧ繝ｳ邱ｨ髮・ム繧､繧｢繝ｭ繧ｰ
class _EditMissionDialog extends StatefulWidget {
  final Mission mission;

  const _EditMissionDialog({required this.mission});

  @override
  State<_EditMissionDialog> createState() => _EditMissionDialogState();
}

class _EditMissionDialogState extends State<_EditMissionDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.mission.name);
    _descriptionController = TextEditingController(
      text: widget.mission.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ繧堤ｷｨ髮・),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '繝溘ャ繧ｷ繝ｧ繝ｳ蜷・),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: '隱ｬ譏趣ｼ井ｻｻ諢擾ｼ・),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('繝溘ャ繧ｷ繝ｧ繝ｳ蜷阪ｒ蜈･蜉帙＠縺ｦ縺上□縺輔＞')));
              return;
            }

            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'description':
                  _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
            });
          },
          child: const Text('譖ｴ譁ｰ'),
        ),
      ],
    );
  }
}
