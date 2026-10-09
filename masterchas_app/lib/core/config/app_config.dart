class AppConfig {
  /// Единый номер для обычных звонков клиентов мастерам (через оператора).
  /// Клиент, выбравший «Обычный звонок», всегда звонит сюда, а не на личный номер мастера.
  static const masterHotline = '+992979117007';
  static const masterHotlineLabel = '+992 97 911 70 07';

  /// Продакшн API (тот же адрес, что в run.sh).
  /// Для локальной разработки: --dart-define=BASE_URL=http://10.0.2.2:5000/api
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    // HTTPS — весь трафик (вход, чат, файлы) зашифрован. Сертификат Let's Encrypt на api.emaster.tj.
    defaultValue: 'https://api.emaster.tj/api',
  );

  /// SignalR hub для уведомлений о заказах.
  static String get ordersHubUrl {
    const host = String.fromEnvironment(
      'HUB_URL',
      defaultValue: 'https://api.emaster.tj/hubs/orders',
    );
    return host;
  }

  /// SignalR hub для чата.
  static String get chatHubUrl {
    const host = String.fromEnvironment(
      'CHAT_HUB_URL',
      defaultValue: 'https://api.emaster.tj/hubs/chat',
    );
    return host;
  }

  /// Supabase сайта: там живёт edge-функция ai-photo-diagnosis (ИИ по фото, Claude).
  /// Это публичный anon-ключ (он и так есть в сборке сайта), секретный ключ Claude хранится только на сервере.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ccddmufdmptmpvgxnezu.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNjZGRtdWZkbXB0bXB2Z3huZXp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2OTE1MDQsImV4cCI6MjA5OTI2NzUwNH0.CiJUzcdD2DI5LgUfFn7yfmkxoXhxGEa7o6n0qP_qUX0',
  );
}
