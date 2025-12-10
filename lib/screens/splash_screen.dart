import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'home_screen.dart';
import '../services/deeplink_service.dart';

/// スプラッシュ画面
/// 
/// アプリ起動時に表示され、初期化処理を実行後にホーム画面へ遷移
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// 初期化処理
  Future<void> _initialize() async {
    // DeeplinkServiceにBuildContextを設定
    final deeplinkService = Provider.of<DeeplinkService>(context, listen: false);
    deeplinkService.setContext(context);

    // スプラッシュ表示時間（最低2秒）
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // ホーム画面へ遷移
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.alarm,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'めざましリレー',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '起床リレーで朝活を楽しもう',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
