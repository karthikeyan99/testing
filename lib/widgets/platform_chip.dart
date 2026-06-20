import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../utils/theme.dart';

Color marketplaceColor(Marketplace m) =>
    m == Marketplace.flipkart ? AppColors.flipkart : AppColors.amazon;

/// Small coloured label identifying a marketplace.
class PlatformChip extends StatelessWidget {
  final Marketplace marketplace;
  final bool dense;

  const PlatformChip({super.key, required this.marketplace, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final color = marketplaceColor(marketplace);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        marketplace.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );
  }
}
