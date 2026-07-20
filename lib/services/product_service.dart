import 'dart:io';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/product.dart';

class ProductService {
  final _client = ApiClient.instance;

  /// Keyword search — GET /search
  Future<List<Product>> searchByKeyword(String query, {String? state}) async {
    final res = await _client.get(ApiConfig.search, query: {
      'q': query,
      if (state != null) 'state': state,
    });
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Category/state browse — GET /listings. ListingController::index()
  /// filters by `category` (the category slug/string) and `state`
  /// (Nigerian state) — it has no `location` filter.
  Future<List<Product>> browse({String? category, String? state}) async {
    final res = await _client.get(ApiConfig.listings, query: {
      if (category != null) 'category': category,
      if (state != null) 'state': state,
    });
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Convenience wrapper used by the home/category screens — routes to
  /// keyword search when a query is present, otherwise a filtered browse.
  Future<List<Product>> search({String? query, String? category, String? state}) {
    if (query != null && query.trim().isNotEmpty) return searchByKeyword(query.trim(), state: state);
    return browse(category: category, state: state);
  }

  Future<List<Product>> recommended() async {
    final res = await _client.get(ApiConfig.listingsRecommended);
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Product>> trending() async {
    final res = await _client.get(ApiConfig.listingsTrending);
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// GET /listings/{id} — ListingController::show() returns the listing
  /// under a `listing` key, not `data` (only the index/search/browse
  /// endpoints use `data`).
  Future<Product> getById(String id) async {
    final res = await _client.get(ApiConfig.listing(id));
    return Product.fromJson(Map<String, dynamic>.from(res.data['listing'] ?? res.data['data'] ?? res.data));
  }

  /// POST /favorites/toggle — backend flips the state and returns the
  /// resulting favorite status; the optimistic UI already assumed the new
  /// state so this call is mostly fire-and-forget (see FavoritesProvider).
  Future<void> toggleFavorite(String listingId) async {
    await _client.post(ApiConfig.favoritesToggle, data: {'listing_id': listingId});
  }

  Future<List<Product>> getFavorites() async {
    final res = await _client.get(ApiConfig.favorites);
    final list = (res.data['data'] ?? res.data) as List;
    return list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Creates a listing (product/service/property). Requires the caller to
  /// have already confirmed KYC + active subscription — see
  /// [VendorStatusProvider.canPostAd], which gates the Post Ad flow before
  /// this is ever called (the backend also double-enforces this via the
  /// `can_post_listing` middleware on POST /listings).
  ///
  /// Photos are uploaded in a *second* call to POST /listings/{id}/images,
  /// matching the backend's separate image-upload route.
  Future<Product> createListing({
    required String type,
    required String category, // category slug — ListingController::store() validates `category` as a required string
    required String title,
    required String description,
    required double price,
    String? priceUnit,
    required String location,
    required String state, // required by ListingController::store()
    int? bedrooms,
    int? bathrooms,
    String? furnishing,
    int? squareFeet,
    String? listingMode,
    List<File> photos = const [],
  }) async {
    final res = await _client.post(ApiConfig.listings, data: {
      'type': type,
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'price_unit': priceUnit ?? 'unit',
      'location': location,
      'state': state,
      // Property-specific fields (bedrooms, etc.) aren't top-level columns
      // on listings, but ListingController::store() does persist whatever
      // is sent under `attributes` verbatim — nest them there instead of
      // sending flat fields the backend would silently drop.
      if (bedrooms != null || bathrooms != null || furnishing != null || squareFeet != null || listingMode != null)
        'attributes': {
          if (bedrooms != null) 'bedrooms': bedrooms,
          if (bathrooms != null) 'bathrooms': bathrooms,
          if (furnishing != null) 'furnishing': furnishing,
          if (squareFeet != null) 'square_feet': squareFeet,
          if (listingMode != null) 'listing_mode': listingMode,
        },
    });

    var product = Product.fromJson(Map<String, dynamic>.from(res.data['listing'] ?? res.data['data'] ?? res.data));

    if (photos.isNotEmpty) {
      await uploadListingImages(product.id, photos);
      product = await getById(product.id); // refresh with photo URLs attached
    }

    return product;
  }

  Future<void> uploadListingImages(String listingId, List<File> photos) async {
    final formData = FormData.fromMap({
      'images': [
        for (final f in photos) await MultipartFile.fromFile(f.path, filename: f.path.split('/').last),
      ],
    });
    await _client.postMultipart(ApiConfig.listingImages(listingId), formData);
  }

  Future<void> updateListing(String id, Map<String, dynamic> fields) async {
    await _client.put(ApiConfig.listing(id), data: fields);
  }

  Future<void> deleteListing(String id) async {
    await _client.delete(ApiConfig.listing(id));
  }

  /// e.g. { status: 'active' | 'paused' | 'sold' }
  Future<void> updateListingStatus(String id, String status) async {
    await _client.patch(ApiConfig.listingStatus(id), data: {'status': status});
  }
}
