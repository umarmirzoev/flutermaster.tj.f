import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

class AdminDataBuilder extends ConsumerWidget {
  const AdminDataBuilder({
    super.key,
    required this.builder,
    this.loading,
    this.error,
  });

  final Widget Function(BuildContext context, AdminDataState data) builder;
  final Widget? loading;
  final Widget Function(Object error)? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDataProvider);

    return async.when(
      data: (data) => builder(context, data),
      loading: () =>
          loading ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
      error: (e, _) =>
          error?.call(e) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ошибка загрузки: $e', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.read(adminDataProvider.notifier).refresh(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
