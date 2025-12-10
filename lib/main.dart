import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/deeplink_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final storageService = StorageService();
  final deeplinkService = DeeplinkService();
  
  await authService.initialize();
  deeplinkService.initialize();
  
  runApp(MezamashiRelayApp(
    authService: authService,
    storageService: storageService,
    deeplinkService: deeplinkService,
  ));
}

class MezamashiRelayApp extends StatelessWidget {
  final AuthService authService;
  final StorageService storageService;
  final DeeplinkService deeplinkService;

  const MezamashiRelayApp({
    super.key,
    required this.authService,
    required this.storageService,
    required this.deeplinkService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<StorageService>.value(value: storageService),
        Provider<DeeplinkService>.value(value: deeplinkService),
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
