import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/vendor_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _vendorService = VendorService();
  int _activeListings = 0;
  int _totalViews = 0;
  int _chats = 0;

  @override
  void initState() {
    super.initState();
    _loadVendorStats();
  }

  Future<void> _loadVendorStats() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isVendor) return;
    try {
      final stats = await _vendorService.getDashboard();
      setState(() {
        _activeListings = stats.activeListings;
        _totalViews = stats.totalViews;
        _chats = stats.messages;
      });
    } catch (_) {
      // leave stats at zero if the dashboard call fails
    }
  }

  Future<void> _showEditSheet() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final businessController = TextEditingController(text: user?.businessName ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
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
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                decoration: const InputDecoration(hintText: 'Full name'),
              ),
              const SizedBox(height: 16),
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '08012345678'),
              ),
              if (auth.isVendor) ...[
                const SizedBox(height: 16),
                const Text('Business Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: businessController,
                  decoration: const InputDecoration(hintText: 'Business name'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final success = await context.read<AuthProvider>().updateProfile({
      'full_name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      if (auth.isVendor) 'business_name': businessController.text.trim(),
    });

    if (!mounted) return;
    if (success) {
      AppMessenger.showSuccess('Profile updated successfully.');
    } else {
      AppMessenger.showError('Could not update your profile. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.t('myProfile')),
        actions: [
          TextButton.icon(
            onPressed: _showEditSheet,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(auth.isVendor ? Icons.storefront_outlined : Icons.person_outline, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(label: Text(auth.isVendor ? locale.t('vendor') : locale.t('buyer')), backgroundColor: AppColors.primaryLight),
                      if (user?.isVerified ?? false) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          avatar: Icon(Icons.verified, size: 14, color: Colors.white),
                          label: Text('Verified'),
                          backgroundColor: AppColors.success,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        user?.memberSince != null ? 'Joined ${_formatMonthYear(user!.memberSince!)}' : '',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      if (user?.rating != null && user!.rating > 0) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(' ${user.rating.toStringAsFixed(1)} rating', style: const TextStyle(fontSize: 13)),
                      ],
                    ],
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
                  Text(locale.t('accountInformation'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? ''),
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.call_outlined, label: 'Phone', value: user?.phone ?? 'Not provided'),
                  if (auth.isVendor) ...[
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.storefront_outlined, label: 'Business Name', value: user?.businessName ?? 'Not provided'),
                  ],
                ],
              ),
            ),
          ),
          if (auth.isVendor) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locale.t('yourStatistics'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatBox(value: '$_activeListings', label: locale.t('activeListings'))),
                        const SizedBox(width: 10),
                        Expanded(child: _StatBox(value: '$_totalViews', label: locale.t('totalViews'))),
                        const SizedBox(width: 10),
                        Expanded(child: _StatBox(value: '$_chats', label: 'Chats')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF6F7F9), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFFF6F7F9), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
