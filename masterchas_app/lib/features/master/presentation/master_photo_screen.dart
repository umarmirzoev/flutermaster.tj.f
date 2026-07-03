import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/master_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/master_registration_draft_provider.dart';
import '../data/master_avatar_presets.dart';
import 'widgets/master_avatar.dart';

class MasterPhotoScreen extends ConsumerStatefulWidget {
  const MasterPhotoScreen({super.key});

  @override
  ConsumerState<MasterPhotoScreen> createState() => _MasterPhotoScreenState();
}

class _MasterPhotoScreenState extends ConsumerState<MasterPhotoScreen> {
  String? _selectedAsset;
  String? _galleryBase64;
  bool _isSubmitting = false;

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _galleryBase64 = base64Encode(bytes);
      _selectedAsset = null;
    });
  }

  Future<void> _submit({required bool skipPhoto}) async {
    if (_isSubmitting) return;

    final draft = ref.read(masterRegistrationDraftProvider);
    if (!draft.hasProfile || draft.selectedServices.isEmpty) {
      context.go('/master/skills');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authProvider.notifier).signUpAsMaster(
            lastName: draft.lastName,
            firstName: draft.firstName,
            patronymic: draft.patronymic,
            isSelfEmployed: draft.isSelfEmployed,
            companyName: draft.companyName,
            selectedServices: draft.selectedServices.toList(),
            avatarAsset: skipPhoto ? null : _selectedAsset,
            avatarGalleryBase64: skipPhoto ? null : _galleryBase64,
          );
      ref.read(masterRegistrationDraftProvider.notifier).reset();
      if (mounted) context.go('/master/submitted');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedAsset != null || _galleryBase64 != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isSubmitting ? null : () => context.go('/master/skills'),
                    icon: const Icon(LucideIcons.arrow_left, color: masterNavy),
                  ),
                  Text(
                    'master.tj',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: masterNavy,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => _submit(skipPhoto: true),
                    child: Text(
                      'Пропустить',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: masterNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Фото профиля',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: masterNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Выберите фото из предложенных или загрузите своё из галереи.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final asset in masterAvatarPresets)
                          GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () => setState(() {
                                      _selectedAsset = asset;
                                      _galleryBase64 = null;
                                    }),
                            child: presetAvatarThumb(
                              asset,
                              size: 88,
                              selected: _selectedAsset == asset,
                            ),
                          ),
                        if (_galleryBase64 != null)
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedAsset = null;
                            }),
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: masterNavy, width: 3),
                              ),
                              child: ClipOval(
                                child: Image.memory(
                                  base64Decode(_galleryBase64!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickFromGallery,
                      icon: const Icon(LucideIcons.image, size: 20),
                      label: Text(
                        'Выбрать из галереи',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: masterNavy,
                        side: const BorderSide(color: masterNavy, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting || !hasSelection
                      ? null
                      : () => _submit(skipPhoto: false),
                  style: FilledButton.styleFrom(
                    backgroundColor: masterNavy,
                    disabledBackgroundColor: masterNavy.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Отправка...' : 'Далее',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
