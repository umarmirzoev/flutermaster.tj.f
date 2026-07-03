import '../../services/data/services_catalog.dart';
import 'masters_data.dart';

/// Result of analyzing a user's problem description.
class AiMatchResult {
  const AiMatchResult({
    required this.category,
    required this.service,
    required this.masters,
    this.mayNeedProduct = false,
  });

  final ServiceCategory category;
  final ServiceItem service;
  final List<MasterItem> masters;
  final bool mayNeedProduct;
}

/// Districts where masters are available.
const masterDistricts = <String>[
  'Сино',
  'Шохмансур',
  'Фирдавси',
  'Исмоили Сомони',
];

const _productCategories = {
  'Электрика',
  'Сантехника',
  'Мебель и двери',
  'Умный дом',
  'Видеонаблюдение',
  'Кондиционеры',
};

/// Extra Russian/Tajik keyword stems per catalog category.
const _categoryKeywords = <String, List<String>>{
  'Электрика': [
    'розетк', 'выключ', 'провод', 'люстр', 'электр', 'искр', 'ламп', 'свет',
    'щит', 'автомат', 'счетчик', 'барқ', 'сим', 'напряжен',
  ],
  'Сантехника': [
    'кран', 'течет', 'течёт', 'течь', 'смесител', 'унитаз', 'труб', 'канализа',
    'бойлер', 'душ', 'раковин', 'засор', 'вода', 'сантех', 'об ', 'крана',
  ],
  'Отделка': [
    'шпаклев', 'штукатур', 'обои', 'плитк', 'гипсокартон', 'откос', 'стен', 'ороиш',
  ],
  'Мебель и двери': [
    'мебел', 'шкаф', 'кухн', 'двер', 'замок', 'полк', 'сборк', 'дар',
  ],
  'Умный дом': [
    'умн', 'домофон', 'замок', 'датчик', 'освещен', 'интеллектуал', 'зирак',
  ],
  'Видеонаблюдение': [
    'камер', 'видео', 'cctv', 'наблюден', 'регистратор',
  ],
  'Уборка': [
    'уборк', 'чистк', 'мыть', 'тоза', 'химчист',
  ],
  'Кондиционеры': [
    'кондицион', 'фреон', 'охлажден', 'сплит',
  ],
  'Отопление': [
    'отоплен', 'радиатор', 'котел', 'котёл', 'тепл', 'гарм',
  ],
  'Малярные работы': [
    'покраск', 'краск', 'фасад', 'потолок', 'ранг',
  ],
  'Полы и ламинат': [
    'ламинат', 'линолеум', 'паркет', 'пол', 'стяжк', 'фарш',
  ],
};

int _scoreText(String query, String text) {
  final q = query.toLowerCase();
  final t = text.toLowerCase();
  if (t.isEmpty) return 0;
  if (q.contains(t)) return 12;
  var score = 0;
  for (final part in t.split(RegExp(r'[\s,/()\-]+'))) {
    if (part.length >= 4 && q.contains(part)) score += 6;
    if (part.length >= 5) {
      final stem = part.substring(0, 5);
      if (q.contains(stem)) score += 4;
    }
  }
  return score;
}

int _scoreService(String query, ServiceItem svc, String catRu) {
  var score = _scoreText(query, svc.ru) + _scoreText(query, svc.tj) + _scoreText(query, svc.en);
  for (final kw in _categoryKeywords[catRu] ?? const []) {
    if (query.contains(kw)) score += 5;
  }
  return score;
}

/// Analyzes free-text problem description and returns matching category, service and masters.
AiMatchResult? analyzeProblem(
  String query, {
  String? district,
  int? budget,
  bool urgent = false,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return null;

  ServiceCategory? bestCat;
  ServiceItem? bestSvc;
  var bestScore = 0;

  for (final cat in serviceCatalog) {
    var catOnlyScore = 0;
    for (final kw in _categoryKeywords[cat.ru] ?? const []) {
      if (q.contains(kw)) catOnlyScore += 7;
    }
    if (catOnlyScore > bestScore) {
      bestScore = catOnlyScore;
      bestCat = cat;
      bestSvc = cat.services.first;
    }

    for (final svc in cat.services) {
      final score = _scoreService(q, svc, cat.ru);
      if (score > bestScore) {
        bestScore = score;
        bestCat = cat;
        bestSvc = svc;
      }
    }
  }

  bestCat ??= serviceCatalog.last;
  bestSvc ??= bestCat.services.first;

  final masterKey = resolveMasterCategory(bestCat.ru);
  var list = masters.where((m) => m.categories.contains(masterKey)).toList();

  if (district != null && district.isNotEmpty) {
    final filtered = list.where((m) => m.districts.contains(district)).toList();
    if (filtered.isNotEmpty) list = filtered;
  }

  if (budget != null && budget > 0) {
    final filtered = list.where((m) => m.priceMin <= budget).toList();
    if (filtered.isNotEmpty) list = filtered;
  }

  list.sort((a, b) {
    if (urgent && a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
    if (a.isTop != b.isTop) return a.isTop ? -1 : 1;
    return b.rating.compareTo(a.rating);
  });

  return AiMatchResult(
    category: bestCat,
    service: bestSvc,
    masters: list,
    mayNeedProduct: _productCategories.contains(bestCat.ru),
  );
}
