class AppConfig {
  /// Продакшн API (тот же адрес, что в run.sh).
  /// Для локальной разработки: --dart-define=BASE_URL=http://10.0.2.2:5000/api
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://91.227.41.158/api',
  );

  /// SignalR hub для уведомлений о заказах.
  static String get ordersHubUrl {
    const host = String.fromEnvironment(
      'HUB_URL',
      defaultValue: 'http://91.227.41.158/hubs/orders',
    );
    return host;
  }

  /// SignalR hub для чата.
  static String get chatHubUrl {
    const host = String.fromEnvironment(
      'CHAT_HUB_URL',
      defaultValue: 'http://91.227.41.158/hubs/chat',
    );
    return host;
  }
}
