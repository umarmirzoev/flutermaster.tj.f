class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isInitialized = false,
  });

  final bool isAuthenticated;
  final bool isInitialized;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isInitialized,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
