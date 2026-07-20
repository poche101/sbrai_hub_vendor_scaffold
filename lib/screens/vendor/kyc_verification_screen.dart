import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../models/kyc_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/vendor_status_provider.dart';
import '../../services/kyc_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/otp_verification_dialog.dart';
import '../../widgets/text_verification_dialog.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final _kycService = KycService();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<VendorStatusProvider>().refresh());
  }

  void _applyStatus(KycStatus? status) {
    if (status == null || !mounted) return;
    context.read<VendorStatusProvider>().updateKyc(status);
  }

  Future<void> _verifyEmail() async {
    final email = context.read<AuthProvider>().currentUser?.email ?? '';
    final status = await OtpVerificationDialog.show(
      context,
      title: 'Verify Email',
      target: email,
      targetLabel: 'email',
      onSendCode: () => _kycService.sendEmailOtp(),
      onVerify: (otp) => _kycService.verifyEmailOtp(otp),
    );
    _applyStatus(status);
    if (status != null) AppMessenger.showSuccess('Email verified successfully!');
  }

  Future<void> _verifyPhone() async {
    final phone = context.read<AuthProvider>().currentUser?.phone ?? '';
    final status = await OtpVerificationDialog.show(
      context,
      title: 'Verify Phone',
      target: phone.isEmpty ? 'your phone number' : phone,
      targetLabel: 'phone',
      onSendCode: () => _kycService.sendPhoneOtp(),
      onVerify: (otp) => _kycService.verifyPhoneOtp(otp),
    );
    _applyStatus(status);
    if (status != null) AppMessenger.showSuccess('Phone number verified successfully!');
  }

  Future<void> _verifyIdentity() async {
    final isVendor = context.read<AuthProvider>().isVendor;

    if (!isVendor) {
      // Buyers only need NIN — per business rules, no method picker.
      final ok = await TextVerificationDialog.show(
        context,
        title: 'Identity Verification',
        label: 'National Identification Number (NIN)',
        hint: '11-digit NIN',
        keyboardType: TextInputType.number,
        maxLength: 11,
        validator: (v) => v.length != 11 ? 'NIN must be exactly 11 digits' : null,
        onSubmit: (v, extra) async {
          final status = await _kycService.verifyNin(v);
          _applyStatus(status);
        },
      );
      if (ok == true) AppMessenger.showSuccess('Identity submitted for verification.');
      return;
    }

    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Choose an identity document', style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('NIN'), onTap: () => Navigator.pop(context, 'nin')),
            ListTile(leading: const Icon(Icons.account_balance_outlined), title: const Text('BVN'), onTap: () => Navigator.pop(context, 'bvn')),
            ListTile(leading: const Icon(Icons.directions_car_outlined), title: const Text("Driver's License"), onTap: () => Navigator.pop(context, 'license')),
            ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('International Passport'), onTap: () => Navigator.pop(context, 'passport')),
          ],
        ),
      ),
    );
    if (method == null || !mounted) return;

    bool? ok;
    switch (method) {
      case 'nin':
        ok = await TextVerificationDialog.show(
          context,
          title: 'Identity Verification',
          label: 'National Identification Number (NIN)',
          hint: '11-digit NIN',
          keyboardType: TextInputType.number,
          maxLength: 11,
          validator: (v) => v.length != 11 ? 'NIN must be exactly 11 digits' : null,
          onSubmit: (v, extra) async => _applyStatus(await _kycService.verifyNin(v)),
        );
        break;
      case 'bvn':
        ok = await TextVerificationDialog.show(
          context,
          title: 'Identity Verification',
          label: 'Bank Verification Number (BVN)',
          hint: '11-digit BVN',
          keyboardType: TextInputType.number,
          maxLength: 11,
          validator: (v) => v.length != 11 ? 'BVN must be exactly 11 digits' : null,
          onSubmit: (v, extra) async => _applyStatus(await _kycService.verifyBvn(v)),
        );
        break;
      case 'license':
        ok = await TextVerificationDialog.show(
          context,
          title: 'Identity Verification',
          label: "Driver's License Number",
          hint: 'e.g. AAA00000AA00',
          validator: (v) => v.isEmpty ? 'Enter your license number' : null,
          extraFields: [
            ExtraField(
              key: 'date_of_birth',
              label: 'Date of Birth',
              hint: 'YYYY-MM-DD',
              keyboardType: TextInputType.datetime,
              validator: (v) => DateTime.tryParse(v) == null ? 'Enter a valid date (YYYY-MM-DD)' : null,
            ),
          ],
          onSubmit: (v, extra) async => _applyStatus(await _kycService.verifyDriversLicense(
            licenseNumber: v,
            dateOfBirth: DateTime.parse(extra['date_of_birth']!),
          )),
        );
        break;
      default:
        ok = await TextVerificationDialog.show(
          context,
          title: 'Identity Verification',
          label: 'International Passport Number',
          hint: 'e.g. A00000000',
          validator: (v) => v.isEmpty ? 'Enter your passport number' : null,
          extraFields: [
            ExtraField(
              key: 'last_name',
              label: 'Last Name (as on passport)',
              hint: 'e.g. Okafor',
              validator: (v) => v.isEmpty ? 'Enter your last name' : null,
            ),
            ExtraField(
              key: 'date_of_birth',
              label: 'Date of Birth',
              hint: 'YYYY-MM-DD',
              keyboardType: TextInputType.datetime,
              validator: (v) => DateTime.tryParse(v) == null ? 'Enter a valid date (YYYY-MM-DD)' : null,
            ),
          ],
          onSubmit: (v, extra) async => _applyStatus(await _kycService.verifyPassport(
            passportNumber: v,
            lastName: extra['last_name']!,
            dateOfBirth: DateTime.parse(extra['date_of_birth']!),
          )),
        );
    }
    if (ok == true) AppMessenger.showSuccess('Identity submitted for verification.');
  }

  Future<void> _verifyBusiness() async {
    final ok = await TextVerificationDialog.show(
      context,
      title: 'Business Verification',
      label: 'CAC Registration Number',
      hint: 'e.g. RC1234567',
      validator: (v) => v.isEmpty ? 'Enter your CAC registration number' : null,
      onSubmit: (v, extra) async => _applyStatus(await _kycService.verifyCac(v)),
    );
    if (ok == true) AppMessenger.showSuccess('Business details submitted for verification.');
  }

  @override
  Widget build(BuildContext context) {
    final vendorStatus = context.watch<VendorStatusProvider>();
    final kyc = vendorStatus.kyc;
    final isVendor = context.watch<AuthProvider>().isVendor;
    final locale = context.watch<LocaleProvider>();
    final totalSteps = isVendor ? 4 : 3;
    final completed = [kyc.emailVerified, kyc.phoneVerified, kyc.identityVerified, if (isVendor) kyc.businessVerified]
        .where((v) => v)
        .length;
    final progress = completed / totalSteps;

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('kycVerification'))),
      body: RefreshIndicator(
        onRefresh: () => context.read<VendorStatusProvider>().refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(locale.t('verificationProgress'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _KycStepCard(
              icon: Icons.mail_outline,
              title: locale.t('emailVerification'),
              subtitle: 'Verify your email address',
              status: kyc.email,
              onTap: _isBusy ? null : _verifyEmail,
            ),
            const SizedBox(height: 12),
            _KycStepCard(
              icon: Icons.call_outlined,
              title: locale.t('phoneVerification'),
              subtitle: 'Verify your phone number',
              status: kyc.phone,
              onTap: _isBusy ? null : _verifyPhone,
            ),
            const SizedBox(height: 12),
            _KycStepCard(
              icon: Icons.badge_outlined,
              title: locale.t('identityVerification'),
              subtitle: isVendor ? 'NIN, BVN, license, or passport' : 'NIN required',
              status: kyc.identity,
              rejectionReason: kyc.identityRejectionReason,
              onTap: _isBusy ? null : _verifyIdentity,
            ),
            if (isVendor) ...[
              const SizedBox(height: 12),
              _KycStepCard(
                icon: Icons.apartment_outlined,
                title: locale.t('businessVerification'),
                subtitle: 'Required for the verified badge',
                status: kyc.business,
                rejectionReason: kyc.businessRejectionReason,
                onTap: _isBusy ? null : _verifyBusiness,
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.navy),
                      SizedBox(width: 8),
                      Text('Why verify your account?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVendor ? '• Build trust with buyers and sellers' : '• Contact and chat with verified vendors',
                    style: const TextStyle(color: AppColors.navy),
                  ),
                  const Text('• Access premium features', style: TextStyle(color: AppColors.navy)),
                  Text(
                    isVendor ? '• Get the verified badge' : '• Keep the marketplace safe for everyone',
                    style: const TextStyle(color: AppColors.navy),
                  ),
                  const Text('• Secure your transactions', style: TextStyle(color: AppColors.navy)),
                ],
              ),
            ),
            if (isVendor && kyc.meetsMinimumForSelling) ...[
              const SizedBox(height: 20),
              AppButton(
                label: locale.t('continueToSubscription'),
                onPressed: () => context.push('/vendor/subscription'),
              ),
            ],
            if (!isVendor && kyc.canTransact) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 8),
                    Expanded(child: Text('You\'re verified! You can now call and chat with vendors.', style: TextStyle(color: AppColors.success))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KycStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final KycFieldStatus status;
  final String? rejectionReason;
  final VoidCallback? onTap;

  const _KycStepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    this.rejectionReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status == KycFieldStatus.verified;
    final isPending = status == KycFieldStatus.pending;
    final isRejected = status == KycFieldStatus.rejected;
    final tappable = !isVerified && !isPending;

    Color iconBg;
    Color iconColor;
    IconData trailingIcon;
    Color trailingColor;
    String? statusLabel;

    if (isVerified) {
      iconBg = AppColors.success.withOpacity(0.15);
      iconColor = AppColors.success;
      trailingIcon = Icons.check_circle;
      trailingColor = AppColors.success;
    } else if (isPending) {
      iconBg = const Color(0xFFFFF3D6);
      iconColor = AppColors.warning;
      trailingIcon = Icons.hourglass_top;
      trailingColor = AppColors.warning;
      statusLabel = 'Under review by our team';
    } else if (isRejected) {
      iconBg = AppColors.danger.withOpacity(0.12);
      iconColor = AppColors.danger;
      trailingIcon = Icons.refresh;
      trailingColor = AppColors.danger;
      statusLabel = rejectionReason != null ? 'Rejected: $rejectionReason — tap to resubmit' : 'Rejected — tap to resubmit';
    } else {
      iconBg = AppColors.primaryLight;
      iconColor = AppColors.primary;
      trailingIcon = Icons.error_outline;
      trailingColor = AppColors.warning;
    }

    return Card(
      child: ListTile(
        onTap: tappable ? onTap : null,
        leading: CircleAvatar(backgroundColor: iconBg, child: Icon(icon, color: iconColor)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(statusLabel ?? subtitle, style: statusLabel != null ? TextStyle(color: trailingColor) : null),
        trailing: Icon(trailingIcon, color: trailingColor),
      ),
    );
  }
}
