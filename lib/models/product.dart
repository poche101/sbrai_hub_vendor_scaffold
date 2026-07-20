import 'category.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String? priceUnit;
  final String location;
  final List<String> photoUrls;
  final ListingType type;
  final String categoryId;

  // Property-specific
  final int? bedrooms;
  final int? bathrooms;
  final String? furnishing;
  final int? squareFeet;
  final bool isForSale;

  // Seller info
  final String sellerId;
  final String sellerName;
  final bool sellerVerified;
  final double sellerRating;
  final DateTime? sellerMemberSince;
  final String? sellerPhone;

  final bool isFavorited;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.priceUnit,
    required this.location,
    this.photoUrls = const [],
    required this.type,
    required this.categoryId,
    this.bedrooms,
    this.bathrooms,
    this.furnishing,
    this.squareFeet,
    this.isForSale = true,
    required this.sellerId,
    required this.sellerName,
    this.sellerVerified = false,
    this.sellerRating = 0,
    this.sellerMemberSince,
    this.sellerPhone,
    this.isFavorited = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // ListingController::formatListing() returns a flat shape — no
    // nested `seller`/`vendor` object — plus `image_urls` (not `photos`)
    // and `category` as a string (not `category_id`). Property-specific
    // attributes (bedrooms, etc.) are, when present, nested under
    // `attributes` rather than top-level.
    final attributes = (json['attributes'] as Map?) ?? {};
    return Product(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      priceUnit: json['price_unit'],
      location: json['location'] ?? '',
      photoUrls: (json['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      type: listingTypeFromString(json['type']),
      categoryId: (json['category'] ?? '').toString(),
      bedrooms: json['bedrooms'] ?? attributes['bedrooms'],
      bathrooms: json['bathrooms'] ?? attributes['bathrooms'],
      furnishing: json['furnishing'] ?? attributes['furnishing'],
      squareFeet: json['square_feet'] ?? attributes['square_feet'],
      isForSale: (json['listing_mode'] ?? attributes['listing_mode'] ?? 'sale') == 'sale',
      sellerId: (json['vendor_id'] ?? '').toString(),
      sellerName: json['vendor_business_name'] ?? json['vendor_name'] ?? 'Seller',
      sellerVerified: json['vendor_verified'] ?? false,
      sellerRating: (json['vendor_rating'] ?? 0).toDouble(),
      sellerMemberSince: null, // not included in formatListing()'s response
      sellerPhone: null, // not included in formatListing()'s response
      isFavorited: json['is_favorited'] ?? false,
    );
  }

  String get formattedPrice {
    final buf = price.toStringAsFixed(0);
    final withCommas = buf.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₦$withCommas';
  }
}
