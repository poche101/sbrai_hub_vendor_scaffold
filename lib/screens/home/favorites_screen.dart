import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _productService = ProductService();
  List<Product> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final favorites = await _productService.getFavorites();
      setState(() => _favorites = favorites);
    } catch (_) {
      // leave list empty; UI shows the empty state below
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.t('myFavorites'), style: const TextStyle(fontSize: 18)),
            Text('${_favorites.length} ${locale.t('items')}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(color: const Color(0xFFF1F2F4), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_border, size: 40, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(locale.t('noFavoritesYet'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(locale.t('saveItemsLater'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: () => context.go('/home'), child: Text(locale.t('startShopping'))),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: _favorites.length,
                    itemBuilder: (context, i) => ProductCard(product: _favorites[i]),
                  ),
      ),
    );
  }
}
