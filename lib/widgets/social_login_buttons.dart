import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_messenger.dart';
import '../core/config/platform_support.dart';
import '../core/theme/app_colors.dart';
import '../providers/locale_provider.dart';
import 'brand_logos.dart';

/// Google/Facebook continue buttons — always visible to match the
/// design on every platform. On Android/iOS these trigger the real
/// native sign-in flow. On Windows (no native Google/Facebook SDK
/// support), tapping shows a friendly notice instead of silently doing
/// nothing or calling into a platform channel that doesn't exist there.
class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    required this.onGoogle,
    required this.onFacebook,
    this.isLoading = false,
  });

  void _handle(VoidCallback action) {
    if (!PlatformSupport.supportsNativeSocialAuth) {
      AppMessenger.showError('Social sign-in isn\'t available on Windows yet — please use email below.');
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => _handle(onGoogle),
          icon: const GoogleLogo(size: 20),
          label: Text(locale.t('continueWithGoogle')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => _handle(onFacebook),
          icon: const FacebookLogo(size: 20),
          label: Text(locale.t('continueWithFacebook')),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR CONTINUE WITH EMAIL',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
