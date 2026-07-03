import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../auth/providers/auth_provider.dart';
import 'master_cabinet_shell.dart';

class MasterPortfolioScreen extends ConsumerWidget {
  const MasterPortfolioScreen({super.key});

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    await ref.read(authProvider.notifier).addPortfolioPhoto(base64Encode(bytes));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Фото добавлено', style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(authProvider).masterProfile?.portfolioBase64 ?? [];

    return MasterCabinetShell(
      title: 'Портфолио',
      actions: [
        IconButton(
          onPressed: () => _addPhoto(context, ref),
          icon: const Icon(LucideIcons.image_plus, color: masterNavy),
        ),
      ],
      child: photos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.folder_open, size: 56, color: masterNavy),
                    const SizedBox(height: 16),
                    Text(
                      'Портфолио пусто',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: masterNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добавьте фото выполненных работ — клиенты увидят их в вашем профиле',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _addPhoto(context, ref),
                      icon: const Icon(LucideIcons.plus, color: Colors.white),
                      label: Text(
                        'Добавить фото',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: masterNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: photos.length + 1,
              itemBuilder: (context, index) {
                if (index == photos.length) {
                  return GestureDetector(
                    onTap: () => _addPhoto(context, ref),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: masterNavy, width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plus, color: masterNavy, size: 32),
                        ],
                      ),
                    ),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    Uint8List.fromList(base64Decode(photos[index])),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}
