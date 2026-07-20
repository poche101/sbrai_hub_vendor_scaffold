import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_status_provider.dart';
import '../../widgets/app_button.dart';

/// Every path into "Post Ad" (FAB, drawer, dashboard quick action) routes
/// through here first. It checks, in order:
///  1. Is the signed-in user a vendor at all?
///  2. Have they completed the minimum KYC checks (email/phone/identity)?
///  3. Do they have an active subscription (₦25,000 or 10 Espees)?
/// Only if all three pass does it forward to the actual 3-step wizard.
class PostAdGateScreen extends StatefulWidget {
  const PostAdGateScreen({super.key});

  @override
  State<PostAdGateScreen> createState() => _PostAdGateScreenState();
}

class _PostAdGateScreenState extends State<PostAdGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isVendor) return; // buyers see the "become a vendor" state below

    final vendorStatus = context.read<VendorStatusProvider>();
    await vendorStatus.refresh();
    if (!mounted) return;

    if (vendorStatus.canPostAd) {
      context.pushReplacement('/post-ad/flow');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isVendor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post an Ad')),
        body: _InfoState(
          icon: Icons.storefront_outlined,
          title: 'Become a Vendor to Post Ads',
          message: 'Only vendor accounts can list products, services, or property on Sbrai Hub.',
          actionLabel: 'Sign Up as Vendor',
          onAction: () => context.push('/signup/vendor'),
        ),
      );
    }

    final vendorStatus = context.watch<VendorStatusProvider>();

    if (vendorStatus.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post an Ad')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!vendorStatus.kyc.meetsMinimumForSelling) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post an Ad')),
        body: _InfoState(
          icon: Icons.verified_user_outlined,
          title: 'Complete KYC Verification',
          message: 'You need to verify your email, phone, and identity before you can post ads.',
          actionLabel: 'Start KYC Verification',
          onAction: () => context.push('/vendor/kyc'),
        ),
      );
    }

    if (!vendorStatus.subscription.isActive) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post an Ad')),
        body: _InfoState(
          icon: Icons.workspace_premium_outlined,
          title: 'Subscribe to Start Selling',
          message: 'A one-time vendor subscription of ₦25,000 (or 10 Espees) unlocks unlimited ad posting.',
          actionLabel: 'Subscribe Now',
          onAction: () => context.push('/vendor/subscription'),
        ),
      );
    }

    // All checks passed — forward automatically (handled in _check as well,
    // this covers the case where state updates after first build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pushReplacement('/post-ad/flow');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _InfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InfoState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            AppButton(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
