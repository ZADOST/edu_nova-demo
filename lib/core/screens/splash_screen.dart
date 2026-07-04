import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../db/local_auth_db.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      final authDb = await LocalAuthDb.init();
      if (!mounted) return;
      if (authDb.isLoggedIn) {
        context.go('/login');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepTeal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.school_rounded, color: AppTheme.pureWhite, size: 84),
            SizedBox(height: 20),
            Text('EduNova', style: TextStyle(color: AppTheme.pureWhite, fontSize: 40, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Powered by ZAS TECH', style: TextStyle(color: AppTheme.pureWhite, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
