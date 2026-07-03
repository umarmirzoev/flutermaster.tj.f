class AppConfig {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api', // Android эмулятор
    // для iOS симулятора: 'http://localhost:5000/api'
    // для прода: 'https://api.masterchas.tj/api'
  );

  /// SignalR hub для уведомлений о заказах.
  static String get ordersHubUrl {
    const host = String.fromEnvironment(
      'HUB_URL',
      defaultValue: 'http://10.0.2.2:5000/hubs/orders',
    );
    return host;
  }

  /// SignalR hub для чата.
  static String get chatHubUrl {
    const host = String.fromEnvironment(
      'CHAT_HUB_URL',
      defaultValue: 'http://10.0.2.2:5000/hubs/chat',
    );
    return host;
  }
}
