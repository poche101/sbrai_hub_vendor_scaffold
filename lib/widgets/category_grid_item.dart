import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/category.dart';
import '../providers/locale_provider.dart';

/// Category tile shown in Home's grid. Renders the admin-uploaded image
/// (category.iconUrl, from GET /categories) when available, falling back
/// to a generic icon only if the backend hasn't set one — so this always
/// reflects whatever the admin panel actually configured, not a
/// hardcoded local icon set.
class CategoryGridItem extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryGridItem(
      {super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final label = locale.category(category.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.iconUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.category_outlined,
                            color: AppColors.primary,
                            size: 26),
                      )
                    : const Icon(Icons.category_outlined,
                        color: AppColors.primary, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
