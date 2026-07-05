import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/master_favorites_provider.dart';

class MasterFavoriteButton extends ConsumerWidget {
  const MasterFavoriteButton({
    super.key,
    required this.masterKey,
    this.size = 28,
    this.iconSize = 15,
    this.lightBg = true,
  });

  final String masterKey;
  final double size;
  final double iconSize;
  final bool lightBg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(masterFavoritesProvider).contains(masterKey);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(masterFavoritesProvider.notifier).toggle(masterKey),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: lightBg ? Colors.white : Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: iconSize,
          color: isFav ? const Color(0xFFEF4444) : const Color(0xFF8B95A5),
        ),
      ),
    );
  }
}
