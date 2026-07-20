import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../providers/favorites_provider.dart';
import 'contact_gate.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(product.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.05,
                  child: product.photoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.photoUrls.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: AppColors.border),
                        )
                      : Container(
                          color: AppColors.border,
                          child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 40),
                        ),
                ),
                if (product.type == ListingType.service)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(text: 'Service', color: AppColors.navy),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => favorites.toggle(product.id),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFav ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(product.location,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(product.formattedPrice,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (product.priceUnit != null)
                    Text(product.priceUnit!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        product.sellerVerified ? Icons.verified : Icons.shield_outlined,
                        size: 13,
                        color: product.sellerVerified ? AppColors.success : AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(product.sellerName,
                            style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      Text(' ${product.sellerRating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(36),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () async {
                            if (!await ContactGate.ensureVerified(context)) return;
                            _call(product.sellerPhone);
                          },
                          icon: const Icon(Icons.call_outlined, size: 15),
                          label: const Text('Call', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(36),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () async {
                            if (!await ContactGate.ensureVerified(context)) return;
                            if (context.mounted) {
                              context.push('/messages/new?sellerId=${product.sellerId}&productId=${product.id}&sellerName=${Uri.encodeComponent(product.sellerName)}');
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 15),
                          label: const Text('Chat', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _call(String? phone) {
    if (phone == null || phone.isEmpty) return;
    launchUrl(Uri.parse('tel:$phone'));
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
