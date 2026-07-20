import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/vendor_status_provider.dart';

/// Call this before dialing or opening a chat. Returns true if the
/// action should proceed. Vendors are never blocked here (this gate is
/// for buyer-contacting-seller only); an unverified buyer sees a dialog
/// explaining why, with a direct link to KYC.
class ContactGate {
  static Future<bool> ensureVerified(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isVendor) return true; // vendors aren't gated on this check

    final status = context.read<VendorStatusProvider>();
    // Fetch fresh status the first time this is checked in a session.
    if (!status.kyc.canTransact && status.kyc.completedSteps == 0) {
      await status.refresh();
    }
    if (status.kyc.canTransact) return true;

    if (!context.mounted) return false;
    final goToKyc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify your account first'),
        content: const Text(
          'To keep the marketplace safe, you need to verify your email, phone, and NIN before contacting sellers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );

    if (goToKyc == true && context.mounted) {
      context.push('/buyer/kyc');
    }
    return false;
  }
}
