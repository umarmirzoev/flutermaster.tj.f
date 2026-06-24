import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_provider.dart';
import '../models/auth_state.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> tryAutoLogin() async {
    if (state.isInitialized) {
      return state.isAuthenticated;
    }

    final token = await ref.read(secureStorageProvider).readToken();

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true, isInitialized: true);
      return true;
    }

    state = state.copyWith(isAuthenticated: false, isInitialized: true);
    return false;
  }

  Future<void> signIn({required String token}) async {
    await ref.read(secureStorageProvider).writeToken(token);
    state = state.copyWith(isAuthenticated: true, isInitialized: true);
  }

  Future<void> signOut() async {
    await ref.read(secureStorageProvider).deleteToken();
    state = state.copyWith(isAuthenticated: false, isInitialized: true);
  }
}
