import 'package:flutter_riverpod/flutter_riverpod.dart';

class MasterRegistrationDraft {
  const MasterRegistrationDraft({
    this.lastName = '',
    this.firstName = '',
    this.patronymic = '',
    this.isSelfEmployed = true,
    this.companyName,
    this.selectedServices = const {},
  });

  final String lastName;
  final String firstName;
  final String patronymic;
  final bool isSelfEmployed;
  final String? companyName;
  final Set<String> selectedServices;

  bool get hasProfile =>
      lastName.trim().isNotEmpty &&
      firstName.trim().isNotEmpty &&
      patronymic.trim().isNotEmpty;

  MasterRegistrationDraft copyWith({
    String? lastName,
    String? firstName,
    String? patronymic,
    bool? isSelfEmployed,
    String? companyName,
    Set<String>? selectedServices,
  }) {
    return MasterRegistrationDraft(
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      patronymic: patronymic ?? this.patronymic,
      isSelfEmployed: isSelfEmployed ?? this.isSelfEmployed,
      companyName: companyName ?? this.companyName,
      selectedServices: selectedServices ?? this.selectedServices,
    );
  }
}

final masterRegistrationDraftProvider =
    NotifierProvider<MasterRegistrationDraftNotifier, MasterRegistrationDraft>(
  MasterRegistrationDraftNotifier.new,
);

class MasterRegistrationDraftNotifier extends Notifier<MasterRegistrationDraft> {
  @override
  MasterRegistrationDraft build() => const MasterRegistrationDraft();

  void saveProfile({
    required String lastName,
    required String firstName,
    required String patronymic,
    required bool isSelfEmployed,
    String? companyName,
  }) {
    state = state.copyWith(
      lastName: lastName.trim(),
      firstName: firstName.trim(),
      patronymic: patronymic.trim(),
      isSelfEmployed: isSelfEmployed,
      companyName: companyName?.trim(),
    );
  }

  void setSelectedServices(Set<String> services) {
    state = state.copyWith(selectedServices: services);
  }

  void toggleService(String key) {
    final next = Set<String>.from(state.selectedServices);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    state = state.copyWith(selectedServices: next);
  }

  void reset() => state = const MasterRegistrationDraft();
}
