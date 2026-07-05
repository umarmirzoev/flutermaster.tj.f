import '../../masters/data/masters_data.dart';
import '../../services/data/service_catalog_keys.dart';
import '../models/master_application_status.dart';
import '../models/master_profile.dart';
import '../utils/phone_formatter.dart';

/// Учётные данные мастера для входа в кабинет.
class MasterCredential {
  const MasterCredential({
    required this.phoneDigits,
    required this.code,
    required this.master,
  });

  /// 9 локальных цифр без +992 (например `900112233`).
  final String phoneDigits;

  /// 4-значный код входа.
  final String code;

  /// Данные мастера из каталога.
  final MasterItem master;
}

/// Номера и коды всех мастеров Master.tj.
///
/// Формат номера: +992 900 XX XX XX
/// Код входа: средние 4 цифры локального номера (удобно запомнить).
///
/// | Мастер              | Номер              | Код  |
/// |---------------------|--------------------|------|
/// | Гулмахмад Давлатов  | +992 900 11 22 33  | 2233 |
/// | Фаррух Каримов      | +992 900 22 33 44  | 3344 |
/// | Камол Камолов       | +992 900 33 44 55  | 4455 |
/// | Рустам Раджабов     | +992 900 44 55 66  | 5566 |
/// | Алишер Азизов       | +992 900 55 66 77  | 6677 |
/// | Далер Сафаров       | +992 900 66 77 88  | 7788 |
/// | Комрон Набиев       | +992 900 77 88 99  | 8899 |
/// | Шохин Абдуллоев     | +992 900 88 99 00  | 9900 |
/// | Джамшед Хакимов     | +992 900 99 00 11  | 0011 |
/// | Абдулло Мирзоев     | +992 900 00 11 22  | 1122 |
/// | Юсуф Бобоев         | +992 900 11 22 55  | 2255 |
/// | Саид Алиев          | +992 900 22 33 66  | 3366 |
final masterCredentials = <MasterCredential>[
  MasterCredential(phoneDigits: '900112233', code: '2233', master: masters[0]),
  MasterCredential(phoneDigits: '900223344', code: '3344', master: masters[1]),
  MasterCredential(phoneDigits: '900334455', code: '4455', master: masters[2]),
  MasterCredential(phoneDigits: '900445566', code: '5566', master: masters[3]),
  MasterCredential(phoneDigits: '900556677', code: '6677', master: masters[4]),
  MasterCredential(phoneDigits: '900667788', code: '7788', master: masters[5]),
  MasterCredential(phoneDigits: '900778899', code: '8899', master: masters[6]),
  MasterCredential(phoneDigits: '900889900', code: '9900', master: masters[7]),
  MasterCredential(phoneDigits: '900990011', code: '0011', master: masters[8]),
  MasterCredential(phoneDigits: '900001122', code: '1122', master: masters[9]),
  MasterCredential(phoneDigits: '900112255', code: '2255', master: masters[10]),
  MasterCredential(phoneDigits: '900223366', code: '3366', master: masters[11]),
];
/// Нормализует ввод номера до 9 локальных цифр.
String normalizeMasterPhoneDigits(String raw) {
  return localDigitsFromPhone(raw);
}

/// Ищет учётные данные мастера по номеру и коду.
MasterCredential? lookupMasterCredential({
  required String phone,
  required String code,
}) {
  final digits = normalizeMasterPhoneDigits(phone);
  final trimmedCode = code.trim();
  if (digits.length < 9 || trimmedCode.length != 4) return null;

  for (final entry in masterCredentials) {
    if (entry.phoneDigits == digits && entry.code == trimmedCode) {
      return entry;
    }
  }
  return null;
}

/// Проверяет, зарегистрирован ли номер как мастер (без проверки кода).
bool isKnownMasterPhone(String phone) {
  final digits = normalizeMasterPhoneDigits(phone);
  return masterCredentials.any((e) => e.phoneDigits == digits);
}

/// Собирает профиль кабинета из данных каталога мастеров.
MasterProfile buildMasterProfileFromCredential(MasterCredential credential) {
  final master = credential.master;
  final nameParts = master.fullName.split(' ');

  final lastName = nameParts.isNotEmpty ? nameParts.first : '';
  final firstName = nameParts.length > 1 ? nameParts[1] : '';
  final patronymic = nameParts.length > 2 ? nameParts.sublist(2).join(' ') : '';

  final selectedServices = <String>[];
  final servicePrices = <String, int>{};
  for (final category in masterServiceCategories(master)) {
    for (final service in category.services.take(4)) {
      final key = serviceSelectionKey(category, service);
      selectedServices.add(key);
      servicePrices[key] = service.priceAvg;
    }
  }

  return MasterProfile(
    lastName: lastName,
    firstName: firstName,
    patronymic: patronymic,
    isSelfEmployed: true,
    selectedServices: selectedServices,
    servicePrices: servicePrices,
    avatarAsset: master.image,
    applicationStatus: MasterApplicationStatus.approved,
    workDistricts: master.districts,
    scheduleWeekdays: const [1, 2, 3, 4, 5, 6],
    scheduleFromHour: 8,
    scheduleToHour: 20,
  );
}
