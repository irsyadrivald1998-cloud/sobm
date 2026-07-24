# 🚀 SOBM Frontend - Quick Start Guide

## Prerequisites

- Flutter SDK 3.11.5 or higher
- Dart SDK
- Windows 10/11 with Developer Mode enabled (for Windows builds)
- Android Studio (for Android builds)
- Xcode (for iOS builds, Mac only)

## Installation

### 1. Clone Repository
```bash
git clone https://github.com/irsyadrivald1998-cloud/sobm.git
cd sobm/frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Enable Windows Developer Mode (for Windows)
```bash
start ms-settings:developers
```
Enable "Developer Mode" and restart terminal.

## Running the App

### Development Mode
```bash
flutter run -d windows
```

### With Custom API URL
```bash
flutter run -d windows --dart-define=API_BASE_URL=https://your-ngrok-url.ngrok-free.app/api
```

### Production Mode
```bash
flutter run -d windows --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.sobm.com/api
```

## Building for Release

### Windows
```bash
flutter build windows --release --dart-define=ENV=prod
```

### Android
```bash
flutter build apk --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.sobm.com/api
```

### iOS
```bash
flutter build ios --release --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.sobm.com/api
```

## Key Features

### 🔐 Authentication
- Login dengan employee ID
- Forgot password functionality
- Auto-logout on token expiry

### 📊 Dashboard
- Overview statistik
- Activity feed dengan filter
- Real-time notifications
- Quick actions

### ✅ Attendance
- Clock in/out dengan GPS & selfie
- Status: Hadir, Terlambat, Alpa, Cuti, Izin, Sakit
- Today's attendance view

### 📝 Reports
- Submit laporan dengan foto
- Work description
- Issue reporting
- Geo-location validation

### 📱 Offline Mode
- Queue system untuk data offline
- Auto-sync saat online
- Manual sync option
- Connection status indicator

### 🏖️ Leave Management
- Ajukan cuti/izin/sakit
- Upload lampiran
- Date range selection
- Status tracking

### 🐛 Issue Tracking
- View issue details
- Update status (Open/In Progress/Resolved)
- Location & reporter info
- Timeline view

## Configuration

### API Base URL
Edit `lib/app_config.dart`:
```dart
static const String apiBaseUrl = 'https://your-api.com/api';
```

Or use dart-define:
```bash
--dart-define=API_BASE_URL=https://your-api.com/api
```

### Feature Flags
```dart
// app_config.dart
static const bool enableOfflineMode = true;
static const bool enableCrashReporting = true;
static const bool enableAnalytics = environment == 'prod';
```

## Troubleshooting

### Issue: "Building with plugins requires symlink support"
**Solution:** Enable Windows Developer Mode
```bash
start ms-settings:developers
```

### Issue: "API Connection Failed"
**Solution:**
1. Check API URL in Settings (gear icon on login)
2. Verify backend is running
3. Test with curl/postman
4. Check firewall settings

### Issue: "Offline Queue Not Syncing"
**Solution:**
1. Check internet connection
2. Go to "Antrian Offline" page
3. Tap "Sinkronkan Sekarang"
4. Check for error messages

### Issue: "Crash Logs Not Created"
**Solution:**
1. Verify crash reporting is enabled
2. Check file permissions
3. Look for console errors
4. Clear app data and retry

## Project Structure

```
lib/
├── main.dart                      # Entry point
├── app_config.dart                # Environment config
├── app_theme.dart                 # Theme & colors
├── api_service.dart               # API client
├── crash_reporting_service.dart   # Error tracking
├── offline_queue_manager.dart     # Offline sync
├── image_utils.dart               # Image compression
│
├── Pages/
│   ├── login_page.dart
│   ├── home_page.dart
│   ├── activity_log_page.dart
│   ├── attendance_page.dart
│   ├── issue_detail_page.dart
│   ├── leave_submission_page.dart
│   ├── forgot_password_page.dart
│   ├── offline_queue_page.dart
│   ├── admin_dashboard_page.dart
│   └── profile_page.dart
│
└── Widgets/
    ├── environment_banner.dart
    └── ...
```

## Default Credentials (Development)

Contact backend team for test credentials.

## API Endpoints

- `POST /api/login` - Authentication
- `GET /api/schedules` - Get schedules
- `POST /api/reports` - Submit report
- `GET /api/attendance/today` - Today's attendance
- `POST /api/attendance/clock-in` - Clock in
- `POST /api/attendance/clock-out` - Clock out
- `GET /api/reports?page=1` - Activity feed
- `PATCH /api/issues/{id}/status` - Update issue
- `POST /api/leave-submissions` - Submit leave

## Support

- 📧 Email: support@sobm.com
- 📱 GitHub Issues: https://github.com/irsyadrivald1998-cloud/sobm/issues
- 📖 Documentation: See `ENVIRONMENT_CONFIG.md` and `FRONTEND_COMPLETION_SUMMARY.md`

## License

[Your License Here]

---

**Last Updated:** 2026-07-24
**Version:** 1.0.0
