import 'master_profile.dart';

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isInitialized = false,
    this.phone,
    this.displayName,
    this.isGuest = false,
    this.isMaster = false,
    this.masterProfile,
    this.role,
  });

  final bool isAuthenticated;
  final bool isInitialized;
  final String? phone;
  final String? displayName;
  final bool isGuest;
  final bool isMaster;
  final MasterProfile? masterProfile;
  final String? role;

  bool get isAdmin {
    final r = role?.toLowerCase();
    return r == 'admin' || r == 'superadmin';
  }

  /// Client with a real API session (not guest / legacy local token).
  bool get canPlaceOrders =>
      isAuthenticated && !isGuest && !isMaster && !isAdmin;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isInitialized,
    String? phone,
    bool clearPhone = false,
    String? displayName,
    bool clearDisplayName = false,
    bool? isGuest,
    bool? isMaster,
    MasterProfile? masterProfile,
    bool clearMasterProfile = false,
    String? role,
    bool clearRole = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
      phone: clearPhone ? null : (phone ?? this.phone),
      displayName:
          clearDisplayName ? null : (displayName ?? this.displayName),
      isGuest: isGuest ?? this.isGuest,
      isMaster: isMaster ?? this.isMaster,
      masterProfile:
          clearMasterProfile ? null : (masterProfile ?? this.masterProfile),
      role: clearRole ? null : (role ?? this.role),
    );
  }
}
