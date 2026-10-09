import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/realtime/signalr_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../data/admin_credentials.dart';
import '../data/auth_repository.dart';
import '../data/master_credentials.dart';
import '../models/auth_session.dart';
import '../models/master_application_status.dart';
import '../models/auth_state.dart';
import '../models/master_profile.dart';
import '../utils/phone_formatter.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> tryAutoLogin() => initializeAuth(restoreSession: true);

  Future<bool> initializeAuth({bool restoreSession = true}) async {
    if (state.isInitialized) {
      return state.isAuthenticated;
    }

    final storage = ref.read(secureStorageProvider);

    try {
      if (restoreSession) {
        final token = await storage.readToken().timeout(const Duration(seconds: 2));

        if (token != null && token.isNotEmpty) {
          if (token == 'guest-token') {
            _setGuestState();
            return true;
          }

          if (token.startsWith('phone:') ||
              token.startsWith('master:') ||
              token.startsWith('user:') ||
              token.startsWith('admin:')) {
            await _restoreLegacySession(token, storage);
            return state.isAuthenticated;
          }

          final refreshToken = await storage.readRefreshToken().timeout(const Duration(seconds: 2));
          if (refreshToken != null && refreshToken.isNotEmpty) {
            final refreshResult = await ref.read(authRepositoryProvider).refresh();
            if (refreshResult is ApiSuccess<AuthSession>) {
              await _applyApiSession(refreshResult.data, storage);
              return true;
            }
          }

          final role = await storage.readRole().timeout(const Duration(seconds: 2)) ?? 'Client';
          final phone = await storage.readPhone().timeout(const Duration(seconds: 2));
          final savedName = await storage.readDisplayName().timeout(const Duration(seconds: 2));
          final isMaster = role.toLowerCase() == 'master';

          state = state.copyWith(
            isAuthenticated: true,
            isInitialized: true,
            phone: phone,
            displayName: savedName?.trim().isNotEmpty == true
                ? savedName!.trim()
                : (await storage.readNameForPhone(phone) ?? 'Пользователь'),
            isGuest: false,
            isMaster: isMaster,
            role: role,
          );
          _syncNameFromServer();
          try {
            await ref.read(signalRServiceProvider).connect();
          } catch (_) {}
          return true;
        }
      }
    } catch (_) {
      // Secure storage can hang or fail on web — continue as logged out.
    }

    state = state.copyWith(isAuthenticated: false, isInitialized: true);
    return false;
  }

  Future<void> loginMasterWithCode({
    required String phone,
    required String code,
  }) async {
    final credential = lookupMasterCredential(phone: phone, code: code);
    final storage = ref.read(secureStorageProvider);

    // 1) Настоящий вход через сервер: код — это пароль мастера.
    //    Только с серверной сессией мастер получает заказы и пишет клиентам в чат.
    final api = await ref.read(authRepositoryProvider).login(phone, code);
    if (api is ApiSuccess<AuthSession> && api.data.isMaster) {
      await _applyApiSession(api.data, storage);
      if (credential != null) {
        await _persistMaster(buildMasterProfileFromCredential(credential));
      }
      try {
        await ref.read(signalRServiceProvider).connect();
      } catch (_) {}
      return;
    }

    // 2) Сервер недоступен — офлайн-вход по встроенному списку (без чата и заказов).
    if (credential == null) {
      throw Exception(
        api is ApiError<AuthSession> ? api.message : 'Неверный номер или код входа',
      );
    }

    final profile = buildMasterProfileFromCredential(credential);
    final phoneFormatted = formatTjPhone(localDigitsFromPhone(phone));
    await storage.writePhone(phoneFormatted);
    await _persistMaster(profile);
  }

  Future<void> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final result = await ref.read(authRepositoryProvider).login(phone, password);
    if (result is! ApiSuccess<AuthSession>) {
      throw Exception(result is ApiError<AuthSession> ? result.message : 'Ошибка входа');
    }

    await _applyApiSession(result.data, ref.read(secureStorageProvider));
    await _saveClientPassword(phone, password);
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (_) {}
  }

  /// Вход администратора: для сидер-логина — сразу пускаем, API подключаем если доступен.
  Future<void> loginAdminWithPassword({
    required String phone,
    required String password,
  }) async {
    final trimmedPassword = password.trim();
    final localCredential = lookupAdminCredential(
      phone: phone,
      password: trimmedPassword,
    );

    if (localCredential != null) {
      final apiResult = await ref
          .read(authRepositoryProvider)
          .login(phone, trimmedPassword);
      if (apiResult is ApiSuccess<AuthSession> && apiResult.data.isAdmin) {
        await _applyApiSession(
          apiResult.data,
          ref.read(secureStorageProvider),
        );
        try {
          await ref.read(signalRServiceProvider).connect();
        } catch (_) {}
        return;
      }
      await _persistAdmin(localCredential, phone);
      return;
    }

    await loginWithPassword(phone: phone, password: trimmedPassword);
    if (!state.isAdmin) {
      await signOut();
      throw Exception('Нужна роль Admin или SuperAdmin');
    }
  }

  Future<void> _persistAdmin(AdminCredential credential, String rawPhone) async {
    final storage = ref.read(secureStorageProvider);
    final phoneFormatted = formatTjPhone(localDigitsFromPhone(rawPhone));

    await storage.writePhone(phoneFormatted);
    await storage.writeToken('admin:${credential.phoneDigits}');
    await storage.writeRole(credential.role);
    await storage.writeDisplayName(credential.displayName);
    await storage.deleteRefreshToken();

    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
      phone: phoneFormatted,
      displayName: credential.displayName,
      isGuest: false,
      isMaster: false,
      role: credential.role,
      clearMasterProfile: true,
    );
  }

  Future<void> registerWithPassword({
    required String phone,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
  }) async {
    final result = await ref.read(authRepositoryProvider).register(
          phone: phone,
          password: password,
          role: role,
          firstName: firstName,
          lastName: lastName,
        );
    if (result is! ApiSuccess<AuthSession>) {
      throw Exception(result is ApiError<AuthSession> ? result.message : 'Ошибка регистрации');
    }

    await _applyApiSession(result.data, ref.read(secureStorageProvider));
    await _saveClientPassword(phone, password);
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (_) {}
  }

  Future<void> _saveClientPassword(String phone, String password) async {
    final storage = ref.read(secureStorageProvider);
    final json = await storage.readClientPasswordsJson();
    final map = <String, dynamic>{};
    if (json != null && json.isNotEmpty) {
      map.addAll(jsonDecode(json) as Map<String, dynamic>);
    }
    map[localDigitsFromPhone(phone)] = password;
    await storage.writeClientPasswordsJson(jsonEncode(map));
  }

  Future<void> _applyApiSession(AuthSession session, dynamic storage) async {
    final phone = session.phoneNumber.isNotEmpty
        ? session.phoneNumber
        : await storage.readPhone();
    final isMaster = session.isMaster;

    if (phone != null && phone.isNotEmpty) {
      await storage.writePhone(phone);
    }
    await storage.writeRole(session.role);

    // Имя, которое этот номер уже задавал на этом устройстве (не стирается при выходе).
    String? knownName;
    try {
      knownName = await ref.read(secureStorageProvider).readNameForPhone(phone);
    } catch (_) {}

    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
      phone: phone,
      displayName: knownName ?? 'Пользователь',
      isGuest: false,
      isMaster: isMaster,
      role: session.role,
      clearMasterProfile: !isMaster,
    );
    if (knownName != null) {
      try {
        await ref.read(secureStorageProvider).writeDisplayName(knownName);
      } catch (_) {}
    }
    // Подтягиваем имя с сервера — так оно одинаковое на всех устройствах.
    _syncNameFromServer();
  }

  /// Берёт имя из профиля на сервере (GET /profile/me) и сохраняет локально.
  Future<void> _syncNameFromServer() async {
    try {
      final res = await ref.read(dioProvider).get<dynamic>('/profile/me');
      var data = res.data;
      if (data is Map && data['data'] is Map) data = data['data'];
      if (data is! Map) return;
      final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
      if (name.isEmpty || !state.isAuthenticated) return;
      state = state.copyWith(displayName: name);
      final storage = ref.read(secureStorageProvider);
      await storage.writeDisplayName(name);
      final phone = state.phone;
      if (phone != null) await storage.writeNameForPhone(phone, name);
    } catch (_) {
      // Сервер без /profile/me или нет сети — оставляем локальное имя.
    }
  }

  Future<void> _restoreLegacySession(String token, dynamic storage) async {
    final phone = await storage.readPhone().timeout(const Duration(seconds: 2));
    final savedName = await storage.readDisplayName().timeout(const Duration(seconds: 2));
    final isGuest = token == 'guest-token';
    final isMaster = token.startsWith('master:');
    final isAdmin = token.startsWith('admin:');
    MasterProfile? masterProfile;

    if (isMaster) {
      final profileJson = await storage.readMasterProfileJson().timeout(const Duration(seconds: 2));
      if (profileJson != null && profileJson.isNotEmpty) {
        masterProfile = MasterProfile.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
        );
      }
    }

    final role = isAdmin
        ? (await storage.readRole().timeout(const Duration(seconds: 2)) ?? 'Admin')
        : (isMaster ? 'Master' : 'Client');

    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
      phone: phone,
      displayName: isGuest
          ? 'Гость'
          : (masterProfile?.shortName ??
              (savedName?.trim().isNotEmpty == true
                  ? savedName!.trim()
                  : (isAdmin ? 'Администратор' : 'Пользователь'))),
      isGuest: isGuest,
      isMaster: isMaster,
      masterProfile: masterProfile,
      role: role,
    );
  }

  void _setGuestState() {
    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
      clearPhone: true,
      displayName: 'Гость',
      isGuest: true,
      isMaster: false,
      role: 'Guest',
      clearMasterProfile: true,
    );
  }

  Future<void> signInWithPhone(String rawDigits) async {
    final digits = rawDigits.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return;

    final phone = formatTjPhone(digits);
    final storage = ref.read(secureStorageProvider);
    await storage.writePhone(phone);

    state = state.copyWith(
      phone: phone,
      isInitialized: true,
    );
  }

  Future<void> signUpAsMaster({
    required String lastName,
    required String firstName,
    required String patronymic,
    required bool isSelfEmployed,
    String? companyName,
    List<String> selectedServices = const [],
    String? avatarAsset,
    String? avatarGalleryBase64,
    MasterApplicationStatus applicationStatus = MasterApplicationStatus.pending,
  }) async {
    final profile = MasterProfile(
      lastName: lastName.trim(),
      firstName: firstName.trim(),
      patronymic: patronymic.trim(),
      isSelfEmployed: isSelfEmployed,
      companyName: isSelfEmployed ? companyName?.trim() : null,
      selectedServices: selectedServices,
      avatarAsset: avatarAsset,
      avatarGalleryBase64: avatarGalleryBase64,
      applicationStatus: applicationStatus,
    );

    await _persistMaster(profile);
  }

  Future<void> _persistMaster(MasterProfile profile) async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.readToken();
    final isApiSession = token != null &&
        token.isNotEmpty &&
        token != 'guest-token' &&
        !token.startsWith('master:') &&
        !token.startsWith('user:') &&
        !token.startsWith('phone:');

    if (!isApiSession) {
      await storage.writeToken('master:${profile.shortName}');
      await storage.writeRole('Master');
    }

    await storage.writeMasterProfileJson(jsonEncode(profile.toJson()));
    await storage.writeDisplayName(profile.shortName);

    final phone = await storage.readPhone();

    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
      phone: phone,
      displayName: profile.shortName,
      isGuest: false,
      isMaster: true,
      role: 'Master',
      masterProfile: profile,
    );
  }

  Future<void> approveMasterApplication() async {
    final profile = state.masterProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      applicationStatus: MasterApplicationStatus.approved,
    );
    await _persistMaster(updated);
  }

  Future<void> addPortfolioPhoto(String base64Image) async {
    final profile = state.masterProfile;
    if (profile == null || !profile.isApproved) return;

    final updated = profile.copyWith(
      portfolioBase64: [...profile.portfolioBase64, base64Image],
    );
    await _persistMaster(updated);
  }

  Future<void> updateMasterServices({
    required List<String> services,
    required Map<String, int> prices,
  }) async {
    final profile = state.masterProfile;
    if (profile == null) return;

    await _persistMaster(
      profile.copyWith(
        selectedServices: services,
        servicePrices: prices,
      ),
    );
  }

  Future<void> updateMasterCabinet(MasterProfile Function(MasterProfile) update) async {
    final profile = state.masterProfile;
    if (profile == null || !profile.isApproved) return;
    await _persistMaster(update(profile));
  }

  Future<void> signInAsGuest() async {
    final storage = ref.read(secureStorageProvider);
    await storage.writeToken('guest-token');
    await storage.deletePhone();
    await storage.deleteMasterProfile();
    await storage.deleteRole();
    await storage.deleteRefreshToken();

    _setGuestState();
  }

  Future<String?> readSavedPhone() async {
    try {
      return await ref
          .read(secureStorageProvider)
          .readPhone()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  Future<MasterProfile?> readSavedMasterProfile() async {
    try {
      final json = await ref
          .read(secureStorageProvider)
          .readMasterProfileJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return null;
      return MasterProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    await ref.read(secureStorageProvider).writeDisplayName(trimmed);
    final phone = state.phone;
    if (phone != null) {
      try {
        await ref.read(secureStorageProvider).writeNameForPhone(phone, trimmed);
      } catch (_) {}
    }
    state = state.copyWith(displayName: trimmed, isGuest: false);

    // Сохраняем имя на сервере — его увидит собеседник в чате.
    final parts = trimmed.split(RegExp(r'\s+'));
    try {
      await ref.read(dioProvider).put('/profile/me', data: {
        'firstName': parts.first,
        'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      });
    } catch (_) {}
  }

  /// Удаляет аккаунт на сервере и выходит. Возвращает текст ошибки или null.
  Future<String?> deleteAccount() async {
    try {
      await ref.read(dioProvider).delete('/profile/me');
    } catch (e) {
      return 'Не удалось удалить аккаунт. Проверьте интернет и попробуйте снова.';
    }
    try {
      await signOut();
    } catch (_) {}
    return null;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = state.copyWith(
      isAuthenticated: false,
      isInitialized: true,
      clearPhone: true,
      clearDisplayName: true,
      isGuest: false,
      isMaster: false,
      role: null,
      clearMasterProfile: true,
    );
  }
}
