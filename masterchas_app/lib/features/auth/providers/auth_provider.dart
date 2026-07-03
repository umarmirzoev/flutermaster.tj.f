import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/realtime/signalr_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../data/auth_repository.dart';
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

          if (token.startsWith('phone:') || token.startsWith('master:') || token.startsWith('user:')) {
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
            displayName: savedName?.trim().isNotEmpty == true ? savedName!.trim() : 'Пользователь',
            isGuest: false,
            isMaster: isMaster,
            role: role,
          );
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

  Future<void> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final result = await ref.read(authRepositoryProvider).login(phone, password);
    if (result is! ApiSuccess<AuthSession>) {
      throw Exception(result is ApiError<AuthSession> ? result.message : 'Ошибка входа');
    }

    await _applyApiSession(result.data, ref.read(secureStorageProvider));
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (_) {}
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
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (_) {}
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

    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
      phone: phone,
      displayName: 'Пользователь',
      isGuest: false,
      isMaster: isMaster,
      role: session.role,
      clearMasterProfile: !isMaster,
    );
  }

  Future<void> _restoreLegacySession(String token, dynamic storage) async {
    final phone = await storage.readPhone().timeout(const Duration(seconds: 2));
    final savedName = await storage.readDisplayName().timeout(const Duration(seconds: 2));
    final isGuest = token == 'guest-token';
    final isMaster = token.startsWith('master:');
    MasterProfile? masterProfile;

    if (isMaster) {
      final profileJson = await storage.readMasterProfileJson().timeout(const Duration(seconds: 2));
      if (profileJson != null && profileJson.isNotEmpty) {
        masterProfile = MasterProfile.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
        );
      }
    }

    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
      phone: phone,
      displayName: isGuest
          ? 'Гость'
          : (masterProfile?.shortName ??
              (savedName?.trim().isNotEmpty == true ? savedName!.trim() : 'Пользователь')),
      isGuest: isGuest,
      isMaster: isMaster,
      masterProfile: masterProfile,
      role: isMaster ? 'Master' : 'Client',
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

    state = state.copyWith(
      isAuthenticated: true,
      isInitialized: true,
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
    state = state.copyWith(displayName: trimmed, isGuest: false);
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
