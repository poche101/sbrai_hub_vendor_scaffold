import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/config/nigeria_states.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/category_grid_item.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _categoryService = CategoryService();
  final _productService = ProductService();

  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _trending = [];
  bool _isLoading = true;
  String? _error;
  String _selectedState = 'All Nigeria';

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
      final results = await Future.wait([
        _categoryService.getCategories(),
        _productService.recommended(),
        _productService.trending(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _products = results[1] as List<Product>;
        _trending = results[2] as List<Product>;
      });
    } catch (e) {
      setState(() => _error = 'Could not load listings. Pull down to try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _productService.search(
        query: query,
        state: _selectedState == 'All Nigeria' ? null : _selectedState,
      );
      setState(() => _products = results);
    } catch (_) {
      // keep existing list on failure
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onStateChanged(String state) async {
    setState(() => _selectedState = state);
    await _search(_searchController.text);
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 5;
    if (width >= 800) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  int _categoryColumns(double width) {
    if (width >= 900) return 8;
    if (width >= 600) return 6;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ---- Orange hero: nav bar, search, category grid, Trending ----
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7)),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 17),
                          ),
                          const SizedBox(width: 8),
                          const Text('Sbrai Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const Spacer(),
                          PopupMenuButton<AppLanguage>(
                            tooltip: 'Select language',
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('🇳🇬', style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 3),
                                Text(
                                  auth.isVendor ? locale.t('vendor') : locale.t('buyer'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        locale.t('searchPlaceholder'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          PopupMenuButton<String>(
                            tooltip: 'Filter by state',
                            initialValue: _selectedState,
                            onSelected: _onStateChanged,
                            itemBuilder: (context) => NigeriaStates.all
                                .map((s) => PopupMenuItem(
                                      value: s,
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(s)),
                                          if (s == _selectedState) const Icon(Icons.check, size: 16, color: AppColors.primary),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                              constraints: const BoxConstraints(maxWidth: 120),
                              decoration: BoxDecoration(color: AppColors.navyDark, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedState,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: AppColors.navyDark, borderRadius: BorderRadius.circular(10)),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: _search,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: locale.t('searchPlaceholder'),
                                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                                  filled: false,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                        child: const Icon(Icons.search, color: Colors.white, size: 16),
                                      ),
                                      onPressed: () => _search(_searchController.text),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_categories.isEmpty && _isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator(color: Colors.white)),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = _categoryColumns(constraints.maxWidth);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, i) {
                                final cat = _categories[i];
                                return CategoryGridItem(
                                  category: cat,
                                  onTap: () => context.push('/category/${cat.slug}?name=${Uri.encodeComponent(cat.name)}'),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(locale.t('trending'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---- White section: Recommended for You ----
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(locale.t('recommended'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_products.length} ${locale.t('items')}', style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                ),
              )
            else if (_isLoading)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
            else if (_products.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No listings yet. Check back soon!', style: TextStyle(color: AppColors.textMuted))),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _crossAxisCount(constraints.crossAxisExtent);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCard(product: _products[i]),
                        childCount: _products.length,
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/post-ad'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
