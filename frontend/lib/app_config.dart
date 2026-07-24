/// Application configuration with environment support
/// 
/// Usage:
/// - Development: flutter run --dart-define=ENV=dev
/// - Production: flutter run --dart-define=ENV=prod
/// - Custom API URL: flutter run --dart-define=API_BASE_URL=https://custom.api.com/api
class AppConfig {
  // Environment from build args (defaults to 'dev')
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  
  // API Base URL from build args or environment-based defaults
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  // Default API URL based on environment
  static const String _defaultApiBaseUrl = environment == 'prod'
      ? 'https://production.sobm.api/api'
      : 'https://e734-114-10-94-177.ngrok-free.app/api';

  // App name
  static const String appName = 'SOBM - Smart Office Building Management';
  
  // App version
  static const String appVersion = '1.0.0';

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableCrashReporting = String.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: 'true') == 'true';
  static const bool enableAnalytics = environment == 'prod';
  
  // Debug mode
  static const bool isDebug = environment != 'prod';
  
  // Timeouts (in seconds)
  static const int apiTimeout = 30;
  static const int uploadTimeout = 60;
  
  // Offline sync interval (in minutes)
  static const int offlineSyncInterval = 15;
  
  // Image compression settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;
  
  // Get environment display name
  static String get environmentName {
    return switch (environment) {
      'prod' => 'Production',
      'staging' => 'Staging',
      'dev' => 'Development',
      _ => environment,
    };
  }

  // Get environment color
  static const Map<String, int> environmentColors = {
    'prod': 0xFF4CAF50, // Green
    'staging': 0xFFFFA726, // Orange
    'dev': 0xFF42A5F5, // Blue
  };

  static int get environmentColor => environmentColors[environment] ?? 0xFF9E9E9E;
}
