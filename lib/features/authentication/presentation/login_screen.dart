import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/db/local_auth_db.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _bgController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Dynamic breathing background animation
    _bgController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: AppTheme.darkCharcoal,
      end: AppTheme.deepTeal.withValues(alpha: 0.5),
    ).animate(_bgController);

    _colorAnimation2 = ColorTween(
      begin: AppTheme.deepTeal.withValues(alpha: 0.3),
      end: AppTheme.darkCharcoal,
    ).animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network delay for a realistic UI feel during the demo
    await Future.delayed(const Duration(milliseconds: 1500));

    // OFFLINE DEMO LOGIC: Assign role based on typed email keyword
    String role = 'student'; // Default fallback
    if (email.contains('teacher')) {
      role = 'teacher';
    } else if (email.contains('parent')) role = 'parent';
    else if (email.contains('principal') || email.contains('admin')) role = 'principal';
    else if (email.contains('assistant')) role = 'assistant_principal';
    else if (email.contains('hr')) role = 'hr';
    else if (email.contains('accounting') || email.contains('finance')) role = 'accounting';
    else if (email.contains('alumni')) role = 'alumni';

    // Save dummy offline session securely to local device
    final prefs = await SharedPreferences.getInstance();
    final authDb = LocalAuthDb(prefs);

    await authDb.saveSession(
      token: 'offline_demo_token_123', 
      role: role, 
      userId: 'U_001'
    );

    if (mounted) {
      setState(() => _isLoading = false);
      final route = _routeForRole(role);
      context.go(route);
    }
  }

  String _routeForRole(String role) {
    switch (role) {
      case 'student':
        return '/student';
      case 'teacher':
        return '/teacher';
      case 'parent':
        return '/parent';
      case 'assistant_principal':
        return '/assistant_principal';
      case 'principal':
        return '/principal';
      case 'accounting':
        return '/accounting';
      case 'hr':
        return '/hr';
      case 'alumni':
        return '/alumni';
      default:
        return '/login';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_colorAnimation1.value!, _colorAnimation2.value!],
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GlassContainer(
              height: 550,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school_rounded, size: 64, color: AppTheme.mintGlow),
                  const SizedBox(height: 16),
                  const Text(
                    'EDU NOVA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.pureWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by ZAS TECH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.mintGlow.withValues(alpha: 0.8),
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: AppTheme.pureWhite),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.mintGlow),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.pureWhite),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.mintGlow),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.pureWhite,
                            ),
                          )
                        : const Text('SECURE LOGIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}