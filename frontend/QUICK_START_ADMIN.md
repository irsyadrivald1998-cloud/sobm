# 🚀 Quick Start - Admin Dashboard

## Langkah Cepat Untuk Menggunakan Admin Dashboard

### 1️⃣ Sudah Selesai (No Action Needed)
✅ Dashboard page sudah dibuat  
✅ Dependencies sudah terinstall  
✅ Route sudah terdaftar  
✅ Import sudah ada di main.dart

### 2️⃣ Test Dashboard Sekarang

#### Buka file `lib/login_page.dart`, cari method login success, ubah menjadi:

```dart
// SEBELUM (redirect ke /home untuk semua user):
Navigator.pushReplacementNamed(context, '/home');

// SESUDAH (redirect berdasarkan role):
final userData = loginData['user'] as Map<String, dynamic>;
final userRole = userData['role'] as String;

if (userRole == 'admin' || userRole == 'viewer') {
  Navigator.pushReplacementNamed(context, '/admin-dashboard');
} else {
  Navigator.pushReplacementNamed(context, '/home');
}
```

#### Atau untuk testing langsung, tambahkan button test di login page:

```dart
// Di login_page.dart body, tambahkan:
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/admin-dashboard');
  },
  child: const Text('Test Admin Dashboard'),
)
```

### 3️⃣ Run Aplikasi

```bash
cd d:\Semester6\sobm\frontend
flutter run
```

### 4️⃣ Login dengan Admin Account

Di backend, buat user admin jika belum ada:

```bash
cd d:\Semester6\sobm\backend
php artisan tinker
```

```php
User::create([
    'employee_id' => 'ADMIN001',
    'name' => 'Super Admin',
    'email' => 'admin@sobm.com',
    'password' => bcrypt('admin123'),
    'role' => 'admin',
]);
```

### 5️⃣ Test Features

✅ Login dengan `ADMIN001` / `admin123`  
✅ Akan redirect otomatis ke admin dashboard  
✅ Coba toggle theme (light/dark)  
✅ Coba klik quick actions  
✅ Scroll ke bawah lihat semua sections  
✅ Test logout

---

## 🎯 Jika Ingin Integrasi Data Real dari Backend

### Backend (Laravel) - Buat Controller:

```bash
php artisan make:controller Api/AdminController
```

**File**: `app/Http/Controllers/Api/AdminController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\{User, Schedule, Area, Checkpoint, Issue, Report};

class AdminController extends Controller
{
    public function getStats()
    {
        $stats = [
            'totalUsers' => User::count(),
            'activeWorkers' => User::where('role', 'worker')
                ->whereHas('schedules', fn($q) => 
                    $q->whereDate('shift_date', today())
                )->count(),
            'pendingTasks' => Schedule::where('status', 'pending')->count(),
            'completedToday' => Schedule::where('status', 'completed')
                ->whereDate('updated_at', today())->count(),
            'totalAreas' => Area::count(),
            'totalCheckpoints' => Checkpoint::count(),
            'issuesReported' => Issue::where('status', 'open')->count(),
            'reportsToday' => Report::whereDate('created_at', today())->count(),
        ];

        return ApiResponse::success($stats);
    }
}
```

### Tambahkan Route:

**File**: `routes/api.php`

```php
Route::middleware(['auth:sanctum'])->group(function () {
    // ... existing routes
    
    // Admin routes
    Route::middleware('role:admin,viewer')->group(function () {
        Route::get('/admin/stats', [App\Http\Controllers\Api\AdminController::class, 'getStats']);
    });
});
```

### Buat Middleware Role (jika belum ada):

```bash
php artisan make:middleware RoleMiddleware
```

**File**: `app/Http/Middleware/RoleMiddleware.php`

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        if (!$request->user() || !in_array($request->user()->role, $roles)) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized access'
            ], 403);
        }

        return $next($request);
    }
}
```

**Register di** `bootstrap/app.php`:

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'role' => \App\Http\Middleware\RoleMiddleware::class,
    ]);
})
```

### Frontend (Flutter) - Update API Service:

**File**: `lib/api_service.dart`

Tambahkan method baru:

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
```

### Update Admin Dashboard Page:

**File**: `lib/admin_dashboard_page.dart`

Ganti bagian initState dan tambahkan method load stats:

```dart
@override
void initState() {
  super.initState();
  _loadUser();
  _loadStats(); // Tambahkan ini
}

Future<void> _loadStats() async {
  try {
    final statsData = await _api.getAdminStats();
    setState(() {
      _stats = statsData;
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat statistik: $e')),
      );
    }
  }
}
```

---

## 🔥 Shortcut untuk Development

### Test tanpa login:
Buat button test di HomePage atau main screen:

```dart
FloatingActionButton(
  onPressed: () {
    Navigator.pushNamed(context, '/admin-dashboard');
  },
  child: const Icon(Icons.admin_panel_settings),
)
```

### Hot reload setelah perubahan:
```
Tekan 'r' di terminal untuk reload
Tekan 'R' untuk restart
```

### Debug mode:
```dart
// Tambahkan print untuk debug
print('User role: ${userData['role']}');
print('Navigating to admin dashboard');
```

---

## 📋 Checklist Quick Implementation

- [ ] Login page redirect berdasarkan role
- [ ] Test login dengan admin account
- [ ] Verifikasi dashboard tampil lengkap
- [ ] Test theme toggle berfungsi
- [ ] (Opsional) Buat backend API endpoint
- [ ] (Opsional) Update stats dari mock ke real data
- [ ] (Opsional) Tambahkan role middleware di backend

---

## 🎨 Customization Tips

### Ubah warna stats card:
**File**: `lib/admin_dashboard_page.dart` → method `_QuickStatsGrid`

```dart
_StatCardData(
  'Total Users',
  stats['totalUsers'].toString(),
  Icons.people,
  AppTheme.tertiary, // <- Ubah warna di sini
  '+3 hari ini',
),
```

### Tambah quick action button:
**File**: `lib/admin_dashboard_page.dart` → method `_QuickActionsGrid`

```dart
final actions = [
  _QuickAction(
    'Button Baru',
    Icons.add,
    Colors.blue,
    () => print('Clicked!'),
  ),
  // ... actions lainnya
];
```

### Ubah jumlah kolom stats grid:
**File**: `lib/admin_dashboard_page.dart` → `_QuickStatsGrid`

```dart
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3, // <- Ubah dari 2 ke 3 kolom
  childAspectRatio: 1.4,
  // ...
),
```

---

## ❓ FAQ

**Q: Dashboard tidak muncul setelah login?**  
A: Cek role user di database, pastikan role = 'admin' atau 'viewer'

**Q: Chart tidak tampil?**  
A: Jalankan `flutter clean && flutter pub get`

**Q: Bagaimana cara hide dashboard untuk non-admin?**  
A: Dashboard sudah ada guard, tapi pastikan redirect logic ada di login

**Q: Bisa ubah layout dashboard?**  
A: Ya, semua di file `admin_dashboard_page.dart`, modifikasi sesuka hati

**Q: Backend API harus dibuat dulu?**  
A: Tidak, dashboard sudah jalan dengan mock data. API optional untuk data real

---

## 📞 Need Help?

1. Baca `ADMIN_DASHBOARD_README.md` untuk dokumentasi lengkap
2. Lihat `example_admin_integration.dart` untuk contoh kode
3. Cek `IMPLEMENTATION_SUMMARY.md` untuk overview

**Happy Coding! 🎉**
