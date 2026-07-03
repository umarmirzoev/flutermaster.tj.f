import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../auth/models/master_profile.dart';

Widget masterAvatar({
  required MasterProfile profile,
  required double size,
  BoxFit fit = BoxFit.cover,
}) {
  if (profile.avatarGalleryBase64 != null &&
      profile.avatarGalleryBase64!.isNotEmpty) {
    try {
      final bytes = base64Decode(profile.avatarGalleryBase64!);
      return ClipOval(
        child: Image.memory(
          Uint8List.fromList(bytes),
          width: size,
          height: size,
          fit: fit,
        ),
      );
    } catch (_) {
      // fall through to asset / placeholder
    }
  }

  if (profile.avatarAsset != null && profile.avatarAsset!.isNotEmpty) {
    return ClipOval(
      child: Image.asset(
        profile.avatarAsset!,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(size, profile),
      ),
    );
  }

  return _placeholder(size, profile);
}

Widget _placeholder(double size, MasterProfile profile) {
  final initial = profile.firstName.isNotEmpty
      ? profile.firstName[0].toUpperCase()
      : '?';
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFE8ECF3),
    ),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: TextStyle(
        fontSize: size * 0.38,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1D243D),
      ),
    ),
  );
}

Widget presetAvatarThumb(String asset, {required double size, bool selected = false}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? const Color(0xFF1D243D) : Colors.transparent,
        width: 3,
      ),
    ),
    child: ClipOval(
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE8ECF3),
          child: Icon(Icons.person, size: size * 0.45, color: const Color(0xFF1D243D)),
        ),
      ),
    ),
  );
}
