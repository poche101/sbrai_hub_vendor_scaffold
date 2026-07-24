import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image logo with storefront fallback
            Image.asset(
              'assets/images/sbrai-logo.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sbrai Hub',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Building Materials • Furniture • Professional Services',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
