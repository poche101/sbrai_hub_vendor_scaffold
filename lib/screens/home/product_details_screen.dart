import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/contact_gate.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _productService = ProductService();
  Product? _product;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final product = await _productService.getById(widget.productId);
      setState(() => _product = product);
    } catch (e) {
      setState(() => _error = 'Could not load this listing.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('Product Details')), body: Center(child: Text(_error!)));
    }
    if (_product == null) {
      return Scaffold(appBar: AppBar(title: const Text('Product Details')), body: const Center(child: CircularProgressIndicator()));
    }

    final p = _product!;

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (!await ContactGate.ensureVerified(context)) return;
                    launchUrl(Uri.parse('tel:${p.sellerPhone ?? ''}'));
                  },
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call Seller'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (!await ContactGate.ensureVerified(context)) return;
                    if (context.mounted) {
                      context.push('/messages/new?sellerId=${p.sellerId}&productId=${p.id}&sellerName=${Uri.encodeComponent(p.sellerName)}');
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat Now'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: p.photoUrls.isNotEmpty
                  ? CachedNetworkImage(imageUrl: p.photoUrls.first, fit: BoxFit.cover)
                  : Container(color: AppColors.border),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(p.formattedPrice, style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              if (p.priceUnit != null) ...[
                                const SizedBox(width: 8),
                                Text(p.priceUnit!, style: const TextStyle(color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(p.location, style: const TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Description', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(p.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seller Information', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(p.sellerName.isNotEmpty ? p.sellerName[0] : '?',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(p.sellerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        if (p.sellerVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, size: 16, color: AppColors.success),
                                        ],
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: Colors.amber),
                                        Text(' ${p.sellerRating.toStringAsFixed(1)} rating', style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      border: Border.all(color: const Color(0xFFF0D48A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                            SizedBox(width: 8),
                            Text('Sbrai Safety Tips', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('• Do not pay in advance until materials are delivered to your site', style: TextStyle(fontSize: 13, color: AppColors.warning)),
                        Text('• Always inspect products before making payment', style: TextStyle(fontSize: 13, color: AppColors.warning)),
                        Text('• Meet sellers in public or safe locations', style: TextStyle(fontSize: 13, color: AppColors.warning)),
                        Text('• Report suspicious activity to Sbrai support', style: TextStyle(fontSize: 13, color: AppColors.warning)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
