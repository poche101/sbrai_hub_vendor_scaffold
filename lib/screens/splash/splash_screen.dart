import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    final auth = context.read<AuthProvider>();
    void go() {
      if (!mounted) return;
      if (auth.isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/role-select');
      }
    }

    if (auth.status == AuthStatus.unknown) {
      // Poll briefly until session restore completes.
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 150));
        if (auth.status != AuthStatus.unknown) {
          go();
          return false;
        }
        return mounted;
      });
    } else {
      go();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text('Sbrai Hub', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Building Materials • Furniture • Professional Services',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
