import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mezamashi_relay/services/auth_service.dart';
import 'package:mezamashi_relay/services/storage_service.dart';
import 'package:mezamashi_relay/services/deeplink_service.dart';
import 'package:mezamashi_relay/services/ble_service.dart';
import 'package:mezamashi_relay/services/alarm_service.dart';
import 'package:mezamashi_relay/services/session_service.dart';
import 'package:mezamashi_relay/services/notification_service.dart';
import 'package:mezamashi_relay/services/statistics_service.dart';
import 'package:mezamashi_relay/services/chat_service.dart';
import 'package:mezamashi_relay/services/theme_service.dart';
import 'package:mezamashi_relay/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // サービスを初期化
    final authService = AuthService();
    final storageService = StorageService();
    final deeplinkService = DeeplinkService();
    final bleService = BLEService();
    final alarmService = AlarmService();
    final sessionService = SessionService(storageService, bleService);
    final notificationService = NotificationService();
    final statisticsService = StatisticsService();
    final chatService = ChatService();
    final themeService = ThemeService();

    await authService.initialize();
    await alarmService.initialize();

    // アプリを起動
    await tester.pumpWidget(
      MezamashiRelayApp(
        authService: authService,
        storageService: storageService,
        deeplinkService: deeplinkService,
        bleService: bleService,
        alarmService: alarmService,
        sessionService: sessionService,
        notificationService: notificationService,
        statisticsService: statisticsService,
        chatService: chatService,
        themeService: themeService,
      ),
    );

    // スプラッシュ画面が表示されることを確認
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('めざましリレー'), findsOneWidget);
  });
}
