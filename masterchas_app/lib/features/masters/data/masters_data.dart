import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/l10n/app_locale.dart';
import '../../services/data/services_catalog.dart';

/// A real master listing (mirrors the `master_listings` table).
class MasterItem {
  const MasterItem({
    required this.fullName,
    required this.phone,
    required this.image,
    required this.bio,
    required this.categories,
    required this.districts,
    required this.experienceYears,
    required this.rating,
    required this.reviews,
    required this.priceMin,
    required this.priceMax,
    required this.completedOrders,
    required this.isTop,
    required this.isOnline,
    this.imageBytes,
  });

  final String fullName;
  final String phone;
  final String image;
  final String bio;
  final List<String> categories; // canonical Russian category keys
  final List<String> districts;
  final int experienceYears;
  final double rating;
  final int reviews;
  final int priceMin;
  final int priceMax;
  final int completedOrders;
  final bool isTop;
  final bool isOnline;
  final Uint8List? imageBytes;

  /// Primary localized profession (first category).
  String profession(AppLocale locale) => localizedCategory(categories.first, locale);

  /// All localized categories joined.
  String categoriesLabel(AppLocale locale) =>
      categories.map((c) => localizedCategory(c, locale)).join(' · ');
}

/// Translation table for the canonical Russian category keys.
const Map<String, Map<AppLocale, String>> _catLabels = {
  'Сантехника': {
    AppLocale.ru: 'Сантехник',
    AppLocale.en: 'Plumber',
    AppLocale.tg: 'Сантехник',
    AppLocale.zh: '水管工',
  },
  'Электрика': {
    AppLocale.ru: 'Электрик',
    AppLocale.en: 'Electrician',
    AppLocale.tg: 'Барқчӣ',
    AppLocale.zh: '电工',
  },
  'Умный дом': {
    AppLocale.ru: 'Умный дом',
    AppLocale.en: 'Smart home',
    AppLocale.tg: 'Хонаи ҳушманд',
    AppLocale.zh: '智能家居',
  },
  'Сварочные работы': {
    AppLocale.ru: 'Сварщик',
    AppLocale.en: 'Welder',
    AppLocale.tg: 'Кафшергар',
    AppLocale.zh: '焊工',
  },
  'Отделка': {
    AppLocale.ru: 'Отделочник',
    AppLocale.en: 'Finisher',
    AppLocale.tg: 'Ороишгар',
    AppLocale.zh: '装修工',
  },
  'Отопление': {
    AppLocale.ru: 'Отопление',
    AppLocale.en: 'Heating',
    AppLocale.tg: 'Гармидиҳӣ',
    AppLocale.zh: '供暖',
  },
  'Кондиционеры': {
    AppLocale.ru: 'Кондиционеры',
    AppLocale.en: 'AC technician',
    AppLocale.tg: 'Кондитсионерҳо',
    AppLocale.zh: '空调',
  },
  'Уборка': {
    AppLocale.ru: 'Уборка',
    AppLocale.en: 'Cleaning',
    AppLocale.tg: 'Тозакунӣ',
    AppLocale.zh: '保洁',
  },
  'Видеонаблюдение': {
    AppLocale.ru: 'Видеонаблюдение',
    AppLocale.en: 'CCTV',
    AppLocale.tg: 'Видеоназорат',
    AppLocale.zh: '监控',
  },
  'Мебель и двери': {
    AppLocale.ru: 'Мебель и двери',
    AppLocale.en: 'Furniture & doors',
    AppLocale.tg: 'Мебел ва дарҳо',
    AppLocale.zh: '家具与门',
  },
  'Ремонт под ключ': {
    AppLocale.ru: 'Ремонт под ключ',
    AppLocale.en: 'Turnkey repair',
    AppLocale.tg: 'Таъмири пурра',
    AppLocale.zh: '整装维修',
  },
  'Плитка': {
    AppLocale.ru: 'Плиточник',
    AppLocale.en: 'Tiler',
    AppLocale.tg: 'Кошинкор',
    AppLocale.zh: '瓷砖工',
  },
  'Другие услуги': {
    AppLocale.ru: 'Мастер на час',
    AppLocale.en: 'Handyman',
    AppLocale.tg: 'Устои умумӣ',
    AppLocale.zh: '杂工',
  },
  'Аварийные 24/7': {
    AppLocale.ru: 'Аварийная служба 24/7',
    AppLocale.en: 'Emergency 24/7',
    AppLocale.tg: 'Хизмати фаврӣ 24/7',
    AppLocale.zh: '紧急服务24/7',
  },
};

String localizedCategory(String ru, AppLocale locale) =>
    _catLabels[ru]?[locale] ?? ru;

/// Quick-filter chips used on the masters page (canonical Russian keys).
const masterFilterChips = <String>[
  'Электрика',
  'Сантехника',
  'Мебель и двери',
  'Отделка',
];

const masters = <MasterItem>[
  MasterItem(
    fullName: 'Гулмахмад Давлатов',
    phone: '+992 900 11 22 33',
    image: 'assets/images/master_4.png',
    bio: 'Специалист по сантехнике и электрике. Гипрозем и весь район Сино.',
    categories: ['Сантехника', 'Электрика'],
    districts: ['Сино'],
    experienceYears: 12,
    rating: 4.9,
    reviews: 124,
    priceMin: 50,
    priceMax: 300,
    completedOrders: 124,
    isTop: true,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Фаррух Каримов',
    phone: '+992 900 22 33 44',
    image: 'assets/images/master_5.png',
    bio: 'Электрика любой сложности, установка систем «Умный дом» в Зарафшоне.',
    categories: ['Электрика', 'Умный дом'],
    districts: ['Сино'],
    experienceYears: 10,
    rating: 5.0,
    reviews: 180,
    priceMin: 60,
    priceMax: 400,
    completedOrders: 180,
    isTop: true,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Камол Камолов',
    phone: '+992 900 33 44 55',
    image: 'assets/images/master_6.png',
    bio: 'Сварочные работы и металлоконструкции. Шохмансур.',
    categories: ['Сварочные работы', 'Отделка'],
    districts: ['Шохмансур'],
    experienceYears: 8,
    rating: 4.8,
    reviews: 210,
    priceMin: 100,
    priceMax: 800,
    completedOrders: 210,
    isTop: true,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Рустам Раджабов',
    phone: '+992 900 44 55 66',
    image: 'assets/images/master_7.png',
    bio: 'Опытный сантехник. Отопление, водоснабжение, канализация.',
    categories: ['Сантехника', 'Отопление'],
    districts: ['Фирдавси'],
    experienceYears: 15,
    rating: 4.7,
    reviews: 320,
    priceMin: 80,
    priceMax: 500,
    completedOrders: 320,
    isTop: true,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Алишер Азизов',
    phone: '+992 900 55 66 77',
    image: 'assets/images/master_8.png',
    bio: 'Монтаж и обслуживание кондиционеров. Фирдавси.',
    categories: ['Кондиционеры', 'Отопление'],
    districts: ['Фирдавси'],
    experienceYears: 9,
    rating: 4.9,
    reviews: 150,
    priceMin: 75,
    priceMax: 350,
    completedOrders: 150,
    isTop: true,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Далер Сафаров',
    phone: '+992 900 66 77 88',
    image: 'assets/images/master_9.png',
    bio: 'Профессиональная уборка и химчистка мебели в Сино.',
    categories: ['Уборка'],
    districts: ['Сино'],
    experienceYears: 6,
    rating: 4.6,
    reviews: 90,
    priceMin: 40,
    priceMax: 200,
    completedOrders: 90,
    isTop: false,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Комрон Набиев',
    phone: '+992 900 77 88 99',
    image: 'assets/images/master_10.png',
    bio: 'Видеонаблюдение и домофоны. Район Исмоили Сомони.',
    categories: ['Видеонаблюдение', 'Электрика'],
    districts: ['Исмоили Сомони'],
    experienceYears: 7,
    rating: 4.8,
    reviews: 110,
    priceMin: 90,
    priceMax: 600,
    completedOrders: 110,
    isTop: true,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Шохин Абдуллоев',
    phone: '+992 900 88 99 00',
    image: 'assets/images/master_11.png',
    bio: 'Сборка мебели, установка межкомнатных дверей. Шохмансур.',
    categories: ['Мебель и двери'],
    districts: ['Шохмансур'],
    experienceYears: 5,
    rating: 4.7,
    reviews: 80,
    priceMin: 55,
    priceMax: 300,
    completedOrders: 80,
    isTop: false,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Джамшед Хакимов',
    phone: '+992 900 99 00 11',
    image: 'assets/images/master_3.png',
    bio: 'Капитальный ремонт квартир под ключ в Сино.',
    categories: ['Ремонт под ключ', 'Отделка'],
    districts: ['Сино'],
    experienceYears: 11,
    rating: 4.5,
    reviews: 60,
    priceMin: 120,
    priceMax: 2000,
    completedOrders: 60,
    isTop: false,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Абдулло Мирзоев',
    phone: '+992 900 00 11 22',
    image: 'assets/images/master_12.png',
    bio: 'Мастер по плитке и отделочным работам. Фирдавси.',
    categories: ['Отделка', 'Плитка'],
    districts: ['Фирдавси'],
    experienceYears: 10,
    rating: 4.8,
    reviews: 140,
    priceMin: 110,
    priceMax: 500,
    completedOrders: 140,
    isTop: true,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Юсуф Бобоев',
    phone: '+992 900 11 22 55',
    image: 'assets/images/master_1.png',
    bio: 'Мелкий бытовой ремонт, мастер на час в Исмоили Сомони.',
    categories: ['Другие услуги'],
    districts: ['Исмоили Сомони'],
    experienceYears: 4,
    rating: 4.6,
    reviews: 70,
    priceMin: 35,
    priceMax: 150,
    completedOrders: 70,
    isTop: false,
    isOnline: true,
  ),
  MasterItem(
    fullName: 'Саид Алиев',
    phone: '+992 900 22 33 66',
    image: 'assets/images/master_2.png',
    bio: 'Аварийная служба 24/7. Вскрытие замков, сантехника, электрика.',
    categories: ['Аварийные 24/7', 'Электрика', 'Сантехника'],
    districts: ['Сино', 'Фирдавси', 'Шохмансур', 'Исмоили Сомони'],
    experienceYears: 13,
    rating: 4.9,
    reviews: 200,
    priceMin: 150,
    priceMax: 1000,
    completedOrders: 200,
    isTop: true,
    isOnline: true,
  ),
];

/// Master categories that aren't a standalone catalog category map onto the
/// closest existing one so we can still show their services and prices.
const Map<String, String> _catalogAlias = {
  'Плитка': 'Отделка',
  'Ремонт под ключ': 'Отделка',
  'Сварочные работы': 'Другие услуги',
  'Аварийные 24/7': 'Другие услуги',
};

/// First priced service shown for a master (for generic "Book" button).
ServiceItem? defaultServiceForMaster(MasterItem master) {
  for (final cat in masterServiceCategories(master)) {
    if (cat.services.isNotEmpty) return cat.services.first;
  }
  return null;
}

/// Catalog categories (with services + somoni prices) offered by a master.
List<ServiceCategory> masterServiceCategories(MasterItem m) {
  final result = <ServiceCategory>[];
  final seen = <String>{};
  for (final c in m.categories) {
    final key = _catalogAlias[c] ?? c;
    if (seen.contains(key)) continue;
    for (final cat in serviceCatalog) {
      if (cat.ru == key) {
        result.add(cat);
        seen.add(key);
        break;
      }
    }
  }
  return result;
}

/// Some catalog categories have no dedicated master category, so map them to
/// the closest one that masters actually list.
const Map<String, String> _catalogToMaster = {
  'Малярные работы': 'Отделка',
  'Полы и ламинат': 'Отделка',
};

/// Resolve a services-catalog category (Russian key) to the master category
/// key used for filtering the masters list.
String resolveMasterCategory(String catalogRu) =>
    _catalogToMaster[catalogRu] ?? catalogRu;

/// Masters that offer the given catalog category.
List<MasterItem> mastersForCategory(String catalogRu) {
  final key = resolveMasterCategory(catalogRu);
  return masters.where((m) => m.categories.contains(key)).toList();
}

/// Icon shown next to the "arrival" tag depending on the master's main work.
IconData masterArrivalIcon(MasterItem m) {
  final c = m.categories.first;
  if (c.contains('Электр')) return LucideIcons.zap;
  if (c.contains('Сантех')) return LucideIcons.droplet;
  if (c.contains('Кондицион')) return LucideIcons.wind;
  if (c.contains('Мебель')) return LucideIcons.armchair;
  if (c.contains('Сварочн')) return LucideIcons.flame;
  if (c.contains('Видео')) return LucideIcons.cctv;
  return LucideIcons.wrench;
}
