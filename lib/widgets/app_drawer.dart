import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, String path) {
    Navigator.pop(context); // close the drawer first
    context.push(path); // push (not go) so the destination gets a back arrow
  }

  void _goHome(BuildContext context) {
    Navigator.pop(context);
    context
        .go('/home'); // Home is the root tab — clears back stack intentionally
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final user = auth.currentUser;
    final isVendor = auth.isVendor;
    final avatarUrl = user?.avatarDisplayUrl;
    final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.85),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Close menu',
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          hasPhoto ? NetworkImage(avatarUrl) : null,
                      onBackgroundImageError: hasPhoto
                          ? (exception, stackTrace) {
                              debugPrint('Failed to load avatar: $exception');
                            }
                          : null,
                      child: !hasPhoto
                          ? Icon(
                              isVendor ? Icons.storefront : Icons.person,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? 'Guest',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text(user?.email ?? '',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                            isVendor ? locale.t('vendor') : locale.t('buyer')),
                        backgroundColor: Colors.black26,
                        labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                      if (user?.isVerified ?? false) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          avatar: Icon(Icons.verified,
                              size: 14, color: Colors.white),
                          label: Text('Verified'),
                          backgroundColor: AppColors.success,
                          labelStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: Text(locale.t('home')),
                      onTap: () => _goHome(context)),
                  ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(locale.t('profile')),
                      onTap: () => _navigate(context, '/profile')),
                  if (isVendor) ...[
                    ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text(locale.t('postAd')),
                        onTap: () => _navigate(context, '/post-ad')),
                    ListTile(
                        leading: const Icon(Icons.dashboard_outlined),
                        title: Text(locale.t('dashboard')),
                        onTap: () => _navigate(context, '/vendor/dashboard')),
                    ListTile(
                        leading: const Icon(Icons.credit_card_outlined),
                        title: Text(locale.t('subscription')),
                        onTap: () =>
                            _navigate(context, '/vendor/subscription')),
                  ],
                  ListTile(
                      leading: const Icon(Icons.favorite_border),
                      title: Text(locale.t('favorites')),
                      onTap: () => _navigate(context, '/favorites')),
                  ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(locale.t('messages')),
                      onTap: () => _navigate(context, '/messages')),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(locale.t('kycVerification')),
                    onTap: () => _navigate(
                        context, isVendor ? '/vendor/kyc' : '/buyer/kyc'),
                  ),
                  ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(locale.t('settings')),
                      onTap: () => _navigate(context, '/settings')),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: Text(locale.t('logout'),
                        style: const TextStyle(color: AppColors.danger)),
                    onTap: () {
                      Navigator.pop(context);
                      auth.logout();
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: Text('Sbrai Hub  •  Version 1.0',
                      style: TextStyle(color: AppColors.textMuted))),
            ),
          ],
        ),
      ),
    );
  }
}
