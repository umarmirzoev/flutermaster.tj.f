import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/data/shop_data.dart';
import '../../profile/presentation/profile_dashboard.dart';

/// Profile tab inside the tools shop bottom navigation.
class ShopProfilePage extends ConsumerWidget {
  const ShopProfilePage({super.key, required this.onOpenProduct});

  final void Function(ShopProduct product) onOpenProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileDashboard(
      bottomPadding: 90,
      onOpenProduct: onOpenProduct,
    );
  }
}
