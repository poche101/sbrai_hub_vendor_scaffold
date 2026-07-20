import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Updated to use the asset image logo
              Image.asset(
                'assets/images/sbrai-logo.png',
                height: 50,
                width: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback container if the asset fails to load
                  return Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 40),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                  'Building Materials • Furniture • Professional Services',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              const Text('Create Your Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Choose how you want to use Sbrai Hub',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              _RoleCard(
                icon: Icons.shopping_bag_outlined,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryLight,
                title: "I'm a Buyer",
                subtitle:
                    'Browse products, shop for materials, and hire services',
                features: const [
                  'Search and filter listings',
                  'Chat with verified vendors',
                  'Book professional services',
                  'Location-based search',
                ],
                buttonLabel: 'Sign Up as Buyer',
                buttonColor: AppColors.primary,
                onPressed: () => context.push('/signup/buyer'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.storefront_outlined,
                iconColor: AppColors.navy,
                iconBg: const Color(0xFFEAEBF5),
                title: "I'm a Vendor",
                subtitle:
                    'List products, offer services, and grow your business',
                features: const [
                  'Upload images and list items',
                  'Access seller dashboard',
                  'Get verified badge',
                  'Manage customer chats',
                ],
                buttonLabel: 'Sign Up as Vendor',
                buttonColor: AppColors.navy,
                onPressed: () => context.push('/signup/vendor'),
              ),
              const SizedBox(height: 24),
              const Text('Already have an account?',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign In to Your Account'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "By continuing, you agree to Sbrai's Terms of Service and Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final List<String> features;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 14),
            Text(title,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(f,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
