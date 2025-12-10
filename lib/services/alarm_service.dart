import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// アラーム音を管理するサービス
/// 指定時刻にアラームを鳴らし、スヌーズ・停止機能を提供
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  DateTime? _scheduledTime;
  DateTime? _snoozeTime;

  /// アラームが再生中かどうか
  bool get isPlaying => _isPlaying;

  /// スケジュールされた時刻
  DateTime? get scheduledTime => _scheduledTime;

  /// スヌーズ時刻
  DateTime? get snoozeTime => _snoozeTime;

  /// 初期化（ループ設定）
  Future<void> initialize() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
  }

  /// アラームをスケジュール（指定時刻に鳴らす）
  /// [wakeTime] 起床時刻
  /// [onAlarmStart] アラーム開始時のコールバック
  Future<void> scheduleAlarm(
    DateTime wakeTime, {
    VoidCallback? onAlarmStart,
  }) async {
    _scheduledTime = wakeTime;
    _snoozeTime = null;

    // 現在時刻との差分を計算
    final now = DateTime.now();
    final duration = wakeTime.difference(now);

    if (duration.isNegative) {
      debugPrint('AlarmService: 指定時刻が過去のため、アラームをスケジュールできません');
      return;
    }

    debugPrint('AlarmService: アラームを${wakeTime.hour}:${wakeTime.minute}にスケジュールしました');

    // 指定時刻まで待機してアラームを開始
    Future.delayed(duration, () async {
      if (_scheduledTime == wakeTime) {
        await playAlarm();
        onAlarmStart?.call();
      }
    });
  }

  /// アラームを即座に再生
  Future<void> playAlarm() async {
    if (_isPlaying) {
      debugPrint('AlarmService: アラームは既に再生中です');
      return;
    }

    try {
      await _player.play(AssetSource('alarm.mp3'));
      _isPlaying = true;
      debugPrint('AlarmService: アラームを再生開始しました');
    } catch (e) {
      debugPrint('AlarmService: アラーム再生エラー: $e');
    }
  }

  /// アラームを停止
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      await _player.stop();
      _isPlaying = false;
      _scheduledTime = null;
      _snoozeTime = null;
      debugPrint('AlarmService: アラームを停止しました');
    } catch (e) {
      debugPrint('AlarmService: アラーム停止エラー: $e');
    }
  }

  /// スヌーズ（5分後に再度アラーム）
  /// [onAlarmStart] アラーム再開時のコールバック
  Future<void> snooze({VoidCallback? onAlarmStart}) async {
    await stopAlarm();

    _snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    debugPrint('AlarmService: スヌーズ - ${_snoozeTime!.hour}:${_snoozeTime!.minute}に再開します');

    // 5分後にアラームを再開
    Future.delayed(const Duration(minutes: 5), () async {
      if (_snoozeTime != null) {
        await playAlarm();
        onAlarmStart?.call();
      }
    });
  }

  /// スケジュールをキャンセル
  void cancelSchedule() {
    _scheduledTime = null;
    _snoozeTime = null;
    if (_isPlaying) {
      stopAlarm();
    }
    debugPrint('AlarmService: スケジュールをキャンセルしました');
  }

  /// 音量を設定（0.0 ~ 1.0）
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// リソースを解放
  Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
  }
}
