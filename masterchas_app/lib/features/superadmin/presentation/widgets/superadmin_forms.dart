import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/superadmin_data.dart';
import '../../models/superadmin_models.dart';
import '../../providers/superadmin_provider.dart';
import '../../theme/superadmin_theme.dart';

class SaProductImage extends StatelessWidget {
  const SaProductImage({super.key, required this.product, this.size = 80, this.fit = BoxFit.contain});

  final SaProduct product;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (product.imageBytes != null) {
      return Image.memory(product.imageBytes!, width: size, height: size, fit: fit);
    }
    return Image.asset(product.image, width: size, height: size, fit: fit, errorBuilder: (_, __, ___) => Icon(LucideIcons.package, size: size * 0.5, color: SuperAdminTheme.muted));
  }
}

class SaMasterAvatar extends StatelessWidget {
  const SaMasterAvatar({super.key, required this.master, this.radius = 20});

  final SaMaster master;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (master.imageBytes != null) {
      return CircleAvatar(radius: radius, backgroundImage: MemoryImage(master.imageBytes!));
    }
    return CircleAvatar(radius: radius, backgroundImage: AssetImage(master.avatar));
  }
}

Future<void> showAddProductSheet(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  var category = productCategories.first;
  var image = productPresetImages.first;
  Uint8List? pickedBytes;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Добавить товар', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название товара', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Цена (с.)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
                    items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setLocal(() => category = v ?? category),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'О товаре', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  Text('Фото', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: productPresetImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final path = productPresetImages[i];
                        final on = image == path && pickedBytes == null;
                        return GestureDetector(
                          onTap: () => setLocal(() {
                            image = path;
                            pickedBytes = null;
                          }),
                          child: Container(
                            width: 64,
                            decoration: BoxDecoration(
                              border: Border.all(color: on ? SuperAdminTheme.green : SuperAdminTheme.border, width: on ? 2 : 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(path, fit: BoxFit.contain),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setLocal(() => pickedBytes = bytes);
                      }
                    },
                    icon: const Icon(LucideIcons.upload, size: 16),
                    label: const Text('Загрузить фото с компьютера'),
                  ),
                  if (pickedBytes != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(pickedBytes!, height: 80, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                      if (name.isEmpty || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните название и цену')));
                        return;
                      }
                      ref.read(platformStoreProvider.notifier).addProduct(
                            name: name,
                            category: category,
                            price: price,
                            description: descCtrl.text.trim(),
                            image: image,
                            imageBytes: pickedBytes,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Товар «$name» добавлен')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Сохранить товар'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  nameCtrl.dispose();
  priceCtrl.dispose();
  descCtrl.dispose();
}

Future<void> showAddMasterSheet(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(text: '+992 ');
  var specialization = masterSpecializations.first;
  var avatar = masterPresetAvatars.first;
  Uint8List? pickedBytes;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Добавить мастера', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Имя мастера', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: specialization,
                    decoration: const InputDecoration(labelText: 'Специализация', border: OutlineInputBorder()),
                    items: masterSpecializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setLocal(() => specialization = v ?? specialization),
                  ),
                  const SizedBox(height: 14),
                  Text('Фото', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: masterPresetAvatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final path = masterPresetAvatars[i];
                        final on = avatar == path && pickedBytes == null;
                        return GestureDetector(
                          onTap: () => setLocal(() {
                            avatar = path;
                            pickedBytes = null;
                          }),
                          child: Container(
                            width: 64,
                            decoration: BoxDecoration(
                              border: Border.all(color: on ? SuperAdminTheme.green : SuperAdminTheme.border, width: on ? 2 : 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(path, fit: BoxFit.contain),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setLocal(() => pickedBytes = bytes);
                      }
                    },
                    icon: const Icon(LucideIcons.upload, size: 16),
                    label: const Text('Загрузить фото'),
                  ),
                  if (pickedBytes != null) ...[
                    const SizedBox(height: 8),
                    Center(child: CircleAvatar(radius: 40, backgroundImage: MemoryImage(pickedBytes!))),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (name.isEmpty || phone.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните имя и телефон')));
                        return;
                      }
                      ref.read(platformStoreProvider.notifier).addMaster(
                            name: name,
                            phone: phone,
                            specialization: specialization,
                            avatar: avatar,
                            imageBytes: pickedBytes,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Мастер «$name» добавлен')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Сохранить мастера'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  nameCtrl.dispose();
  phoneCtrl.dispose();
}
