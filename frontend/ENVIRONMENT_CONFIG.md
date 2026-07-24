# Environment Configuration Guide

## Overview

SOBM Frontend mendukung multiple environment configuration untuk memudahkan development, staging, dan production deployment.

## Environment Variables

### 1. Environment Type (`ENV`)

Menentukan environment aplikasi:

```bash
# Development (default)
flutter run

# Development (explicit)
flutter run --dart-define=ENV=dev

# Staging
flutter run --dart-define=ENV=staging

# Production
flutter run --dart-define=ENV=prod
```

### 2. Custom API Base URL (`API_BASE_URL`)

Override default API URL:

```bash
flutter run --dart-define=API_BASE_URL=https://custom.api.com/api
```

### 3. Crash Reporting (`ENABLE_CRASH_REPORTING`)

Enable/disable crash reporting:

```bash
# Enable (default)
flutter run --dart-define=ENABLE_CRASH_REPORTING=true

# Disable
flutter run --dart-define=ENABLE_CRASH_REPORTING=false
```

## Default Configurations

### Development (`dev`)
- **API URL**: `https://e734-114-10-94-177.ngrok-free.app/api`
- **Environment Banner**: Visible (Blue)
- **Crash Reporting**: Enabled
- **Analytics**: Disabled
- **Debug Mode**: Enabled

### Staging (`staging`)
- **API URL**: `https://staging.sobm.api/api` (perlu dikonfigurasi)
- **Environment Banner**: Visible (Orange)
- **Crash Reporting**: Enabled
- **Analytics**: Disabled
- **Debug Mode**: Enabled

### Production (`prod`)
- **API URL**: `https://production.sobm.api/api` (perlu dikonfigurasi)
- **Environment Banner**: Hidden
- **Crash Reporting**: Enabled
- **Analytics**: Enabled
- **Debug Mode**: Disabled

## Build Examples

### Development Build (Windows)
```bash
flutter build windows --dart-define=ENV=dev
```

### Production Build (Windows)
```bash
flutter build windows --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.sobm.com/api
```

### Android Production
```bash
flutter build apk --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.sobm.com/api
```

### iOS Production
```bash
flutter build ios --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.sobm.com/api
```

## Configuration File

Semua konfigurasi dikelola di `lib/app_config.dart`:

```dart
class AppConfig {
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultApiBaseUrl);
  
  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = environment == 'prod';
  
  // Timeouts
  static const int apiTimeout = 30;
  static const int uploadTimeout = 60;
  
  // Image settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;
}
```

## Features by Environment

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| Environment Banner | ✅ | ✅ | ❌ |
| Crash Logs | ✅ | ✅ | ✅ |
| Analytics | ❌ | ❌ | ✅ |
| Debug Logs | ✅ | ✅ | ❌ |
| Offline Mode | ✅ | ✅ | ✅ |
| Error Details | Full | Full | Minimal |

## Crash Reporting

Crash logs disimpan di:
- **Windows**: `C:\Users\<username>\Documents\sobm\crash_logs\`
- **Android**: `/data/data/com.sobm.app/files/crash_logs/`
- **iOS**: `<app_container>/Documents/crash_logs/`

Format file: `crash_YYYYMMDD.log`

Retention: 7 hari (otomatis dihapus)

## Offline Queue

Data offline disimpan di SQLite database:
- **Database**: `offline_queue.db`
- **Auto Sync**: Setiap 15 menit saat online
- **Manual Sync**: Via halaman "Antrian Offline"

## Best Practices

1. **Development**: Gunakan default configuration atau custom API URL dengan ngrok
   ```bash
   flutter run --dart-define=API_BASE_URL=https://abc123.ngrok-free.app/api
   ```

2. **Testing**: Gunakan staging environment
   ```bash
   flutter run --dart-define=ENV=staging
   ```

3. **Production**: Selalu specify API URL dan environment
   ```bash
   flutter build apk --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.sobm.com/api
   ```

4. **CI/CD**: Simpan environment variables di CI/CD secrets

## Troubleshooting

### API Connection Failed
1. Cek environment banner di bagian bawah login page
2. Verify API URL di Settings (gear icon)
3. Test connectivity dengan curl/postman
4. Cek firewall/network settings

### Crash Logs Not Created
1. Verify `ENABLE_CRASH_REPORTING=true`
2. Cek permission file system
3. Lihat console untuk error messages

### Offline Queue Not Working
1. Cek connectivity status
2. Verify database initialization
3. Manual sync via Offline Queue page
4. Clear app data jika database corrupt

## Support

Untuk bantuan lebih lanjut, hubungi tim development atau buka issue di repository.
