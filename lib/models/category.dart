enum ListingType { product, service, property }

ListingType listingTypeFromString(String? v) {
  switch (v) {
    case 'service':
      return ListingType.service;
    case 'property':
      return ListingType.property;
    default:
      return ListingType.product;
  }
}

String listingTypeToString(ListingType t) {
  switch (t) {
    case ListingType.service:
      return 'service';
    case ListingType.property:
      return 'property';
    case ListingType.product:
      return 'product';
  }
}

/// Categories are fully admin-managed (routes/admin.php: create, edit,
/// delete, toggle-active, reorder) — so the app treats [isActive] and
/// [sortOrder] as authoritative from the backend rather than assuming a
/// fixed list. Inactive categories (toggled off by an admin) are filtered
/// out before display; the rest are shown in [sortOrder].
class Category {
  final String id;
  final String slug;
  final String name;
  final ListingType type;
  final String? iconUrl;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    String? slug,
    required this.name,
    required this.type,
    this.iconUrl,
    this.isActive = true,
    this.sortOrder = 0,
  }) : slug = slug ?? id;

  /// ListingController::categories() returns id, name, slug, type, icon,
  /// image_url — and ListingController::store()/index() filter/store
  /// listings by the `category` *string* (the slug), not the numeric id.
  factory Category.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    return Category(
      id: id,
      slug: (json['slug'] ?? id).toString(),
      name: json['name'] ?? '',
      type: listingTypeFromString(json['type']),
      iconUrl: json['icon_url'] ?? json['icon'] ?? json['image_url'],
      isActive: json['is_active'] ?? json['active'] ?? true,
      sortOrder: json['sort_order'] ?? json['order'] ?? 0,
    );
  }

  /// Local fallback categories, shown instantly while /categories loads
  /// and used if the request fails, so the browse screen is never empty.
  /// Mirrors what an admin would typically seed via the admin panel.
  static List<Category> fallback() {
    const names = [
      ['sharp_sand', 'Sharp Sand', ListingType.product],
      ['granite', 'Granite', ListingType.product],
      ['blocks', 'Blocks', ListingType.product],
      ['cement', 'Cement', ListingType.product],
      ['iron_rods', 'Iron Rods', ListingType.product],
      ['paints', 'Paints', ListingType.product],
      ['furniture', 'Furniture', ListingType.product],
      ['scaffolding', 'Scaffolding', ListingType.product],
      ['logistics', 'Logistics', ListingType.service],
      ['borehole', 'Borehole', ListingType.service],
      ['cleaning', 'Cleaning', ListingType.service],
      ['fumigation', 'Fumigation', ListingType.service],
      ['apartments', 'Apartments', ListingType.property],
      ['houses', 'Houses', ListingType.property],
      ['commercial', 'Commercial', ListingType.property],
      ['land', 'Land', ListingType.property],
    ];
    return [
      for (int i = 0; i < names.length; i++)
        Category(id: names[i][0] as String, name: names[i][1] as String, type: names[i][2] as ListingType, sortOrder: i),
    ];
  }
}
