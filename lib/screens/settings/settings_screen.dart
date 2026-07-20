import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_messenger.dart';
import '../../core/config/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/settings_service.dart';
import '../../widgets/password_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _settingsService.getSettings();
      setState(() => _settings = settings);
    } catch (_) {
      // keep sensible defaults if settings can't be fetched
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _update(AppSettings updated) async {
    setState(() => _settings = updated);
    try {
      await _settingsService.updateSettings(updated);
    } catch (_) {
      if (!mounted) return;
      AppMessenger.showError('Could not save that setting. Please try again.');
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              PasswordField(controller: current, label: 'Current Password'),
              const SizedBox(height: 16),
              PasswordField(
                controller: next,
                label: 'New Password',
                hint: 'Minimum 6 characters',
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await context.read<AuthProvider>().changePassword(currentPassword: current.text, newPassword: next.text);
      if (!mounted) return;
      AppMessenger.showSuccess('Password updated successfully.');
    } catch (_) {
      if (!mounted) return;
      AppMessenger.showError('Could not update your password. Check your current password and try again.');
    }
  }

  Future<void> _showInfoDialog(String title, String body) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.5))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all your data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await context.read<AuthProvider>().deleteAccount();
    if (!mounted) return;
    if (success) {
      AppMessenger.showSuccess('Your account has been deleted.');
      // No manual navigation — the router redirects to /role-select
      // automatically once auth.isLoggedIn flips to false.
    } else {
      AppMessenger.showError('Could not delete your account. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: Text(locale.t('settings'))), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(locale.t('notifications'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Manage your notification preferences', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('New Listings'),
                    subtitle: const Text('Get notified about new items in your area'),
                    value: _settings.notifyNewListings,
                    onChanged: (v) => _update(_settings.copyWith(notifyNewListings: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Price Drops'),
                    subtitle: const Text('Alert me when prices drop on favorited items'),
                    value: _settings.notifyPriceDrops,
                    onChanged: (v) => _update(_settings.copyWith(notifyPriceDrops: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Messages'),
                    subtitle: const Text('Receive notifications for new messages'),
                    value: _settings.notifyMessages,
                    onChanged: (v) => _update(_settings.copyWith(notifyMessages: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Promotions'),
                    subtitle: const Text('Receive promotional offers and deals'),
                    value: _settings.notifyPromotions,
                    onChanged: (v) => _update(_settings.copyWith(notifyPromotions: v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(locale.t('privacySecurity'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Control your privacy and account security', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Online Status'),
                    subtitle: const Text("Let others see when you're online"),
                    value: _settings.showOnlineStatus,
                    onChanged: (v) => _update(_settings.copyWith(showOnlineStatus: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Phone Number'),
                    subtitle: Text(auth.isVendor ? 'Display phone number on listings' : 'Display phone number on profile'),
                    value: _settings.showPhoneNumber,
                    onChanged: (v) => _update(_settings.copyWith(showPhoneNumber: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow Messages'),
                    subtitle: const Text('Allow users to send you messages'),
                    value: _settings.allowMessages,
                    onChanged: (v) => _update(_settings.copyWith(allowMessages: v)),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline),
                    title: Text(locale.t('changePassword')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordSheet,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(locale.t('languageRegion'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(locale.t('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  PopupMenuButton<AppLanguage>(
                    initialValue: locale.language,
                    onSelected: (lang) => context.read<LocaleProvider>().setLanguage(lang),
                    itemBuilder: (context) => AppLanguage.values
                        .map((lang) => PopupMenuItem(
                              value: lang,
                              child: Row(
                                children: [
                                  Expanded(child: Text(lang.label)),
                                  if (lang == locale.language) const Icon(Icons.check, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFFF6F7F9), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Expanded(child: Text(locale.language.label)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(locale.t('currency'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ListTile(
                    tileColor: const Color(0xFFF6F7F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(_settings.currency),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInfoDialog('Currency', 'Sbrai Hub currently only supports Nigerian Naira (₦). More currencies are coming soon.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (auth.isVendor)
            Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card_outlined, color: AppColors.primary),
                title: Text(locale.t('subscription')),
                subtitle: const Text('Manage your vendor subscription'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/vendor/subscription'),
              ),
            ),
          if (auth.isVendor) const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(locale.t('termsOfService')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfoDialog(
                    locale.t('termsOfService'),
                    'By using Sbrai Hub, you agree to use the marketplace responsibly, provide accurate listing and account information, and comply with all applicable Nigerian laws. Vendors are responsible for the accuracy of their listings; buyers are responsible for verifying goods and services before payment. Sbrai Hub is not a party to any transaction between buyers and vendors.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(locale.t('privacyPolicy')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfoDialog(
                    locale.t('privacyPolicy'),
                    'Sbrai Hub collects the information you provide (name, email, phone, KYC details) to operate the marketplace, verify accounts, and process payments. We do not sell your personal data. KYC information is used solely for identity verification and is handled in accordance with Nigerian data protection regulations.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(locale.t('helpSupport')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfoDialog(
                    locale.t('helpSupport'),
                    'Need help? Reach our support team at support@sbraisolutions.com or through the in-app chat. We typically respond within 24 hours.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.danger)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locale.t('dangerZone'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 16)),
                  const Text('Irreversible and destructive actions', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: const Color(0xFFFFF5F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: Text(locale.t('logout'), style: const TextStyle(color: AppColors.danger)),
                    onTap: () async {
                      await auth.logout();
                      // No manual navigation — the router redirects
                      // automatically once auth.isLoggedIn flips to false.
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    tileColor: const Color(0xFFFFF5F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                    title: Text(locale.t('deleteAccount'), style: const TextStyle(color: AppColors.danger)),
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('Sbrai Hub v1.0.0', style: TextStyle(color: AppColors.textMuted))),
        ],
      ),
    );
  }
}
