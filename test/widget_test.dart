import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mezamashi_relay/services/auth_service.dart';
import 'package:mezamashi_relay/services/storage_service.dart';
import 'package:mezamashi_relay/services/deeplink_service.dart';
import 'package:mezamashi_relay/services/ble_service.dart';
import 'package:mezamashi_relay/services/session_service.dart';
import 'package:mezamashi_relay/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // サービスを初期化
    final authService = AuthService();
    final storageService = StorageService();
    final deeplinkService = DeeplinkService();
    final bleService = BLEService();
    final sessionService = SessionService(storageService, bleService);

    await authService.initialize();

    // アプリを起動
    await tester.pumpWidget(
      MezamashiRelayApp(
        authService: authService,
        storageService: storageService,
        deeplinkService: deeplinkService,
        bleService: bleService,
        sessionService: sessionService,
      ),
    );

    // スプラッシュ画面が表示されることを確認
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('めざましリレー'), findsOneWidget);
  });
}
