import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

// 繧ｹ繝励Λ繝・す繝･逕ｻ髱｢
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // 蛻晄悄蛹門ｾ・ｩ滂ｼ・遘抵ｼ・
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    
    if (!mounted) return;
    
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
            Icon(Icons.alarm, size: 100, color: Colors.white),
            Icon(
              Icons.alarm,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              '繧√＊縺ｾ縺励Μ繝ｬ繝ｼ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '襍ｷ蠎翫Μ繝ｬ繝ｼ縺ｧ譛晄ｴｻ繧呈･ｽ縺励ｂ縺・,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
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
