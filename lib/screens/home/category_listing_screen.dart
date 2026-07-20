import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';

/// Shows every product/service/property listing under one category.
/// Reached by tapping a category tile on Home — each product card here
/// pushes through to ProductDetailsScreen on tap, same as everywhere else.
class CategoryListingScreen extends StatefulWidget {
  final String categoryId;
  final String? categoryName;
  const CategoryListingScreen({super.key, required this.categoryId, this.categoryName});

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  final _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _productService.search(category: widget.categoryId);
      setState(() => _products = results);
    } catch (_) {
      setState(() => _error = 'Could not load this category. Pull down to try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final title = widget.categoryName != null ? locale.category(widget.categoryName!) : 'Sbrai Hub';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_products.length} ${locale.t('items')}', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                  ),
                ),
              )
            else if (_products.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No listings in this category yet.', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid: more columns as the window widens
                    // (useful on the Windows desktop target).
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1100 ? 5 : (width >= 800 ? 4 : (width >= 560 ? 3 : 2));
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, i) => ProductCard(product: _products[i]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
