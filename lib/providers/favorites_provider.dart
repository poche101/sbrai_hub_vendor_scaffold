import 'package:flutter/foundation.dart';
import '../services/product_service.dart';

/// Optimistic favorites toggling: flips the UI immediately, rolls back
/// if the API call fails — same pattern used in your existing
/// FavoriteProvider for Sbrai Hub's Flutter app.
class FavoritesProvider extends ChangeNotifier {
  final _productService = ProductService();
  final Set<String> _favoriteIds = {};

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> toggle(String productId) async {
    final wasFavorite = _favoriteIds.contains(productId);
    if (wasFavorite) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();

    try {
      await _productService.toggleFavorite(productId);
    } catch (_) {
      // Roll back on failure
      if (wasFavorite) {
        _favoriteIds.add(productId);
      } else {
        _favoriteIds.remove(productId);
      }
      notifyListeners();
    }
  }

  void seed(Iterable<String> ids) {
    _favoriteIds.addAll(ids);
    notifyListeners();
  }
}
