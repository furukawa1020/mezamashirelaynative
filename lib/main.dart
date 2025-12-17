import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/deeplink_service.dart';
import 'services/ble_service.dart';
import 'services/session_service.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'services/statistics_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final storageService = StorageService();
  final deeplinkService = DeeplinkService();
  final bleService = BLEService();
  final alarmService = AlarmService();
  final notificationService = NotificationService();
  final statisticsService = StatisticsService();
  final sessionService = SessionService(storageService, bleService);

  await authService.initialize();
  await alarmService.initialize();
  deeplinkService.initialize();

  runApp(
    MezamashiRelayApp(
      authService: authService,
      storageService: storageService,
      deeplinkService: deeplinkService,
      bleService: bleService,
      alarmService: alarmService,
      notificationService: notificationService,
      sessionService: sessionService,
    ),
  );
}

class MezamashiRelayApp extends StatelessWidget {
  final AuthService authService;
  final StorageService storageService;
  final DeeplinkService deeplinkService;
  final BLEService bleService;
  final AlarmService alarmService;
  final NotificationService notificationService;
  final SessionService sessionService;

  const MezamashiRelayApp({
    super.key,
    required this.authService,
    required this.storageService,
    required this.deeplinkService,
    required this.bleService,
    required this.alarmService,
    required this.notificationService,
    required this.sessionService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<StorageService>.value(value: storageService),
        Provider<DeeplinkService>.value(value: deeplinkService),
        Provider<BLEService>.value(value: bleService),
        Provider<AlarmService>.value(value: alarmService),
        ChangeNotifierProvider<NotificationService>.value(
          value: notificationService,
        ),
        ChangeNotifierProvider<SessionService>.value(value: sessionService),
      ],
      child: MaterialApp(
        title: 'めざましリレー',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
