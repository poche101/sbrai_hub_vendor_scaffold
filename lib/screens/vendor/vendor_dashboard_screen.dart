import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../services/vendor_service.dart';
import '../../widgets/product_card.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _vendorService = VendorService();
  late TabController _tabController;

  DashboardStats? _stats;
  List<Product> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _vendorService.getDashboard(),
        _vendorService.getMyListings(),
      ]);
      setState(() {
        _stats = results[0] as DashboardStats;
        _listings = results[1] as List<Product>;
      });
    } catch (_) {
      // keep prior state; UI shows an empty dashboard rather than crashing
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? DashboardStats();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(locale.t('vendorDashboard')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/post-ad'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(locale.t('postAd')),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                          icon: Icons.inventory_2_outlined,
                          value: '${stats.activeListings}',
                          label: locale.t('activeListings'),
                          color: AppColors.primary),
                      _StatCard(
                          icon: Icons.visibility_outlined,
                          value: '${stats.totalViews}',
                          label: locale.t('totalViews'),
                          color: Colors.blue),
                      _StatCard(
                          icon: Icons.chat_bubble_outline,
                          value: '${stats.messages}',
                          label: locale.t('messages'),
                          color: AppColors.success),
                      _StatCard(
                          icon: Icons.attach_money,
                          value:
                              '₦${(stats.totalSales / 1000).toStringAsFixed(0)}k',
                          label: locale.t('totalSales'),
                          color: AppColors.danger),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: locale.t('overview')),
                      Tab(text: locale.t('myListings')),
                      Tab(text: locale.t('analytics'))
                    ],
                  ),
                  SizedBox(
                    height: 640,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverview(stats, locale),
                        _buildListings(),
                        _buildAnalytics(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview(DashboardStats stats, LocaleProvider locale) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        Card(
          color: AppColors.primaryLight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.card_giftcard, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Ad Voucher',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Chip(
                        label: const Text('Active'),
                        backgroundColor: AppColors.success.withOpacity(0.15),
                        labelStyle: const TextStyle(
                            color: AppColors.success, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Balance',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text('₦${stats.adVoucherBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF3FF),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'This voucher can only be used to promote your listings when the promotion feature launches.',
                    style: TextStyle(fontSize: 12, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(locale.t('recentActivity'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final a in stats.recentActivity)
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary),
                  title: Text(a.message),
                  subtitle: Text(_relativeTime(a.at)),
                ),
              if (stats.recentActivity.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No recent activity yet.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(locale.t('quickActions'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _QuickAction(
                icon: Icons.add_circle_outline,
                label: 'Post New Ad',
                onTap: () => context.push('/post-ad')),
            _QuickAction(
                icon: Icons.people_outline,
                label: 'View Messages',
                onTap: () => context.push('/messages')),
            _QuickAction(
                icon: Icons.show_chart,
                label: 'Analytics',
                onTap: () => _tabController.animateTo(2)),
            _QuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Manage Listings',
                onTap: () => _tabController.animateTo(1)),
          ],
        ),
      ],
    );
  }

  Widget _buildListings() {
    if (_listings.isEmpty) {
      return const Center(
          child: Text('You have no listings yet.',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: _listings.length,
      itemBuilder: (context, i) {
        final product = _listings[i];
        return Stack(
          children: [
            ProductCard(product: product),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) => _onListingAction(action, product),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onListingAction(String action, Product product) async {
    if (action == 'edit') {
      // Adjust this route/param if your edit flow differs from post-ad.
      context.push('/post-ad', extra: product);
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete listing?'),
          content: Text('This will permanently remove "${product.title}".'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final removedIndex = _listings.indexWhere((p) => p.id == product.id);
      setState(() => _listings.removeWhere((p) => p.id == product.id));

      try {
        // Adjust this method name if your VendorService uses a different one.
        await _vendorService.deleteListing(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing deleted.')),
          );
        }
      } catch (_) {
        // rollback on failure
        if (mounted) {
          setState(() {
            final insertAt =
                removedIndex >= 0 && removedIndex <= _listings.length
                    ? removedIndex
                    : 0;
            _listings.insert(insertAt, product);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to delete listing. Try again.')),
          );
        }
      }
    }
  }

  Widget _buildAnalytics() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 40, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Analytics Coming Soon',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'View trends, top listings, and conversion insights will appear here once this feature launches.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
