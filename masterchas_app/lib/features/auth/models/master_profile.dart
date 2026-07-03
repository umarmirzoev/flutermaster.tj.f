import 'master_application_status.dart';

class MasterEarning {
  const MasterEarning({required this.date, required this.amountSomoni});

  final DateTime date;
  final int amountSomoni;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amountSomoni': amountSomoni,
      };

  factory MasterEarning.fromJson(Map<String, dynamic> json) {
    return MasterEarning(
      date: DateTime.parse(json['date'] as String),
      amountSomoni: json['amountSomoni'] as int? ?? 0,
    );
  }
}

class MasterProfile {
  const MasterProfile({
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    this.isSelfEmployed = true,
    this.companyName,
    this.selectedServices = const [],
    this.avatarAsset,
    this.avatarGalleryBase64,
    this.applicationStatus = MasterApplicationStatus.pending,
    this.portfolioBase64 = const [],
    this.workDistricts = const [],
    this.scheduleWeekdays = const [1, 2, 3, 4, 5],
    this.scheduleFromHour = 9,
    this.scheduleToHour = 18,
    this.completedOrders = 0,
    this.activeOrders = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.earnings = const [],
  });

  final String lastName;
  final String firstName;
  final String patronymic;
  final bool isSelfEmployed;
  final String? companyName;
  final List<String> selectedServices;
  final String? avatarAsset;
  final String? avatarGalleryBase64;
  final MasterApplicationStatus applicationStatus;
  final List<String> portfolioBase64;
  final List<String> workDistricts;
  final List<int> scheduleWeekdays;
  final int scheduleFromHour;
  final int scheduleToHour;
  final int completedOrders;
  final int activeOrders;
  final double rating;
  final int reviewCount;
  final List<MasterEarning> earnings;

  int get monthlyIncome {
    final now = DateTime.now();
    return earnings
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<int>(0, (sum, e) => sum + e.amountSomoni);
  }

  String get shortName => '$firstName $lastName'.trim();

  String get fullName =>
      '$lastName $firstName $patronymic'.replaceAll(RegExp(r'\s+'), ' ').trim();

  bool get hasAvatar =>
      (avatarAsset != null && avatarAsset!.isNotEmpty) ||
      (avatarGalleryBase64 != null && avatarGalleryBase64!.isNotEmpty);

  bool get isApproved => applicationStatus == MasterApplicationStatus.approved;

  MasterProfile copyWith({
    String? lastName,
    String? firstName,
    String? patronymic,
    bool? isSelfEmployed,
    String? companyName,
    List<String>? selectedServices,
    String? avatarAsset,
    bool clearAvatarAsset = false,
    String? avatarGalleryBase64,
    bool clearAvatarGallery = false,
    MasterApplicationStatus? applicationStatus,
    List<String>? portfolioBase64,
    List<String>? workDistricts,
    List<int>? scheduleWeekdays,
    int? scheduleFromHour,
    int? scheduleToHour,
    int? completedOrders,
    int? activeOrders,
    double? rating,
    int? reviewCount,
    List<MasterEarning>? earnings,
  }) {
    return MasterProfile(
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      patronymic: patronymic ?? this.patronymic,
      isSelfEmployed: isSelfEmployed ?? this.isSelfEmployed,
      companyName: companyName ?? this.companyName,
      selectedServices: selectedServices ?? this.selectedServices,
      avatarAsset: clearAvatarAsset ? null : (avatarAsset ?? this.avatarAsset),
      avatarGalleryBase64: clearAvatarGallery
          ? null
          : (avatarGalleryBase64 ?? this.avatarGalleryBase64),
      applicationStatus: applicationStatus ?? this.applicationStatus,
      portfolioBase64: portfolioBase64 ?? this.portfolioBase64,
      workDistricts: workDistricts ?? this.workDistricts,
      scheduleWeekdays: scheduleWeekdays ?? this.scheduleWeekdays,
      scheduleFromHour: scheduleFromHour ?? this.scheduleFromHour,
      scheduleToHour: scheduleToHour ?? this.scheduleToHour,
      completedOrders: completedOrders ?? this.completedOrders,
      activeOrders: activeOrders ?? this.activeOrders,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      earnings: earnings ?? this.earnings,
    );
  }

  Map<String, dynamic> toJson() => {
        'lastName': lastName,
        'firstName': firstName,
        'patronymic': patronymic,
        'isSelfEmployed': isSelfEmployed,
        'companyName': companyName,
        'selectedServices': selectedServices,
        'avatarAsset': avatarAsset,
        'avatarGalleryBase64': avatarGalleryBase64,
        'applicationStatus': applicationStatus.name,
        'portfolioBase64': portfolioBase64,
        'workDistricts': workDistricts,
        'scheduleWeekdays': scheduleWeekdays,
        'scheduleFromHour': scheduleFromHour,
        'scheduleToHour': scheduleToHour,
        'completedOrders': completedOrders,
        'activeOrders': activeOrders,
        'rating': rating,
        'reviewCount': reviewCount,
        'earnings': earnings.map((e) => e.toJson()).toList(),
      };

  factory MasterProfile.fromJson(Map<String, dynamic> json) {
    return MasterProfile(
      lastName: json['lastName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      patronymic: json['patronymic'] as String? ?? '',
      isSelfEmployed: json['isSelfEmployed'] as bool? ?? true,
      companyName: json['companyName'] as String?,
      selectedServices: (json['selectedServices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      avatarAsset: json['avatarAsset'] as String?,
      avatarGalleryBase64: json['avatarGalleryBase64'] as String?,
      applicationStatus: MasterApplicationStatus.values.firstWhere(
        (s) => s.name == json['applicationStatus'],
        orElse: () => MasterApplicationStatus.pending,
      ),
      portfolioBase64: (json['portfolioBase64'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      workDistricts: (json['workDistricts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      scheduleWeekdays: (json['scheduleWeekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5],
      scheduleFromHour: json['scheduleFromHour'] as int? ?? 9,
      scheduleToHour: json['scheduleToHour'] as int? ?? 18,
      completedOrders: json['completedOrders'] as int? ?? 0,
      activeOrders: json['activeOrders'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      earnings: (json['earnings'] as List<dynamic>?)
              ?.map((e) => MasterEarning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
