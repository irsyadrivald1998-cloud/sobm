# Admin Dashboard - SOBM Mobile App

## Overview
Dashboard admin yang komprehensif untuk mengelola sistem SOBM Facility Management. Dashboard ini menyediakan tampilan profile admin yang diperkaya dengan statistik sistem, manajemen, dan pengaturan keamanan.

## Fitur Utama

### 1. **Profile Header**
- Avatar dengan badge crown untuk identifikasi admin
- Informasi nama, email, dan role admin
- Gradient badge dengan icon admin panel

### 2. **Ringkasan Sistem (Quick Stats)**
- Total Users - Jumlah pengguna terdaftar
- Pekerja Aktif - Worker yang sedang aktif
- Tugas Pending - Task yang membutuhkan tindakan
- Selesai Hari Ini - Task yang sudah diselesaikan
- Total Areas & Checkpoints - Coverage sistem
- Issues Reported - Masalah yang perlu direview

### 3. **Aktivitas Minggu Ini (Weekly Chart)**
- Bar chart menampilkan aktivitas mingguan
- Visual indikator performa sistem
- Menggunakan package `fl_chart` untuk visualisasi data

### 4. **Aksi Cepat (Quick Actions)**
- Buat Jadwal
- Tambah User
- Lihat Laporan
- Kelola Area

### 5. **Informasi Profil Detail**
- Employee ID
- Email
- Role
- Organisasi

### 6. **Pengaturan Akun**
- Mode Terang/Gelap toggle
- Notifikasi Admin
- Pengaturan Keamanan

### 7. **Manajemen Sistem**
- Kelola Pengguna
- Kelola Area & Checkpoint
- Kelola Issues
- Laporan & Analitik

### 8. **Keamanan**
- Ubah Password
- Autentikasi 2 Faktor (coming soon)
- Riwayat Login (coming soon)

## Instalasi & Setup

### 1. Install Dependencies
Pastikan `fl_chart` sudah ada di `pubspec.yaml`:
```yaml
dependencies:
  fl_chart: ^0.69.0
```

Jalankan:
```bash
flutter pub get
```

### 2. Import di Main App
File sudah ditambahkan di `main.dart`:
```dart
import 'admin_dashboard_page.dart';
```

Route sudah tersedia:
```dart
routes: {
  '/admin-dashboard': (context) => const AdminDashboardPage(),
}
```

## Penggunaan

### Navigasi ke Admin Dashboard

#### Dari Login Page (setelah login sebagai admin):
```dart
if (userData['role'] == 'admin') {
  Navigator.pushReplacementNamed(context, '/admin-dashboard');
} else {
  Navigator.pushReplacementNamed(context, '/home');
}
```

#### Dari halaman lain:
```dart
Navigator.pushNamed(context, '/admin-dashboard');
```

## Integrasi dengan Backend

### API Endpoints yang Dibutuhkan

Saat ini dashboard menggunakan mock data. Untuk integrasi penuh, tambahkan endpoint berikut di backend:

#### 1. **GET /api/admin/stats**
```json
{
  "status": true,
  "data": {
    "totalUsers": 45,
    "activeWorkers": 32,
    "pendingTasks": 18,
    "completedToday": 24,
    "totalAreas": 12,
    "totalCheckpoints": 156,
    "issuesReported": 7,
    "reportsToday": 28
  }
}
```

#### 2. **GET /api/admin/weekly-activity**
```json
{
  "status": true,
  "data": {
    "activities": [28, 32, 24, 30, 35, 22, 18]
  }
}
```

### Update ApiService

Tambahkan method di `api_service.dart`:
```dart
// GET /admin/stats
Future<Map<String, dynamic>> getAdminStats() async {
  final baseUrl = await getBaseUrl();
  final token = await getToken();
  if (token == null) throw Exception('Tidak terautentikasi.');

  final response = await http.get(
    Uri.parse('$baseUrl/admin/stats'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  ).timeout(const Duration(seconds: 10));

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200 && responseData['status'] == true) {
    return responseData['data'] as Map<String, dynamic>;
  } else {
    throw Exception(responseData['message'] ?? 'Gagal mengambil statistik.');
  }
}

// GET /admin/weekly-activity
Future<List<dynamic>> getWeeklyActivity() async {
  final baseUrl = await getBaseUrl();
  final token = await getToken();
  if (token == null) throw Exception('Tidak terautentikasi.');

  final response = await http.get(
    Uri.parse('$baseUrl/admin/weekly-activity'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  ).timeout(const Duration(seconds: 10));

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200 && responseData['status'] == true) {
    return responseData['data']['activities'] as List<dynamic>;
  } else {
    throw Exception(responseData['message'] ?? 'Gagal mengambil aktivitas.');
  }
}
```

## Customization

### Mengubah Mock Data
Di file `admin_dashboard_page.dart`, ubah variabel `_stats`:
```dart
final Map<String, dynamic> _stats = {
  'totalUsers': 45,
  'activeWorkers': 32,
  // ... dst
};
```

### Mengubah Warna Stats Card
Di method `_QuickStatsGrid`, ubah warna pada `_StatCardData`:
```dart
_StatCardData(
  'Total Users',
  stats['totalUsers'].toString(),
  Icons.people,
  AppTheme.tertiary, // <- Ubah warna di sini
  '+3 hari ini',
),
```

### Menambahkan Quick Action Baru
Di `_QuickActionsGrid`, tambahkan item baru:
```dart
final actions = [
  _QuickAction(
    'Action Baru',
    Icons.new_icon,
    AppTheme.statusOk,
    () => _handleNewAction(),
  ),
  // ... actions lainnya
];
```

## Theme Support

Dashboard mendukung light dan dark mode secara otomatis:
- Dark Mode: Gradient dari `surfaceLowest` ke `surface`
- Light Mode: Gradient dari `lightSurfaceLow` ke `lightSurface`

Toggle dilakukan melalui switch di section "Pengaturan Akun".

## Struktur File

```
lib/
├── admin_dashboard_page.dart  # Main admin dashboard
├── api_service.dart           # API service (tambahkan admin endpoints)
├── app_theme.dart             # Theme configuration
├── main.dart                  # App entry + routing
└── ...
```

## Tips & Best Practices

1. **Role-based Navigation**: Pastikan hanya user dengan role `admin` yang bisa akses dashboard ini
2. **Data Caching**: Consider caching stats data untuk performa lebih baik
3. **Error Handling**: Tambahkan proper error handling saat fetch data dari API
4. **Loading States**: Show skeleton loaders saat data sedang dimuat
5. **Refresh**: Implement pull-to-refresh untuk update data real-time

## Troubleshooting

### Error: Package fl_chart not found
```bash
flutter pub get
flutter clean
flutter pub get
```

### Chart tidak muncul
Pastikan `fl_chart` version compatible dengan Flutter SDK Anda.

### Navigation error
Pastikan route `/admin-dashboard` sudah terdaftar di `main.dart`.

## Next Steps

- [ ] Integrasikan dengan backend API
- [ ] Tambahkan real-time data updates
- [ ] Implement detail pages untuk setiap management section
- [ ] Tambahkan export laporan functionality
- [ ] Implement notification system
- [ ] Tambahkan role-based access control yang ketat

## Support

Untuk pertanyaan atau issue, silakan hubungi tim development.
