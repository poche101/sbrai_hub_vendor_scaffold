import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/category.dart';

class CategoryService {
  final _client = ApiClient.instance;

  /// Fetches categories, filters out any an admin has toggled inactive,
  /// and sorts by the admin-configurable [Category.sortOrder] (matches
  /// the drag-to-reorder behavior behind POST admin/categories/reorder).
  Future<List<Category>> getCategories() async {
    List<Category> categories;
    try {
      final res = await _client.get(ApiConfig.categories);
      final list = (res.data['data'] ?? res.data) as List;
      categories = list.map((e) => Category.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      // Keep browsing usable even if the backend call fails.
      categories = Category.fallback();
    }

    final active = categories.where((c) => c.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return active;
  }
}
