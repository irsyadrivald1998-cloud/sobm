# Perbaikan API Routes - Menghapus Prefix /v1

## Masalah
Aplikasi frontend tidak dapat menemukan endpoint `api/schedules` karena:
- Backend routes menggunakan prefix `/v1` → `/api/v1/schedules`
- Frontend memanggil tanpa `/v1` → `/api/schedules`
- Hasil: 404 Not Found

## Solusi yang Diterapkan

### 1. Backend Routes (DIPERBAIKI)
File: `backend/routes/api.php`

**SEBELUM:**
```php
Route::prefix('v1')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    // ... routes lainnya
});
```
Menghasilkan: `/api/v1/login`, `/api/v1/schedules`, dll

**SESUDAH:**
```php
// Hapus prefix v1 - routes langsung di /api/*
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/schedules', [ScheduleController::class, 'index']);
    // ... routes lainnya
});
```
Menghasilkan: `/api/login`, `/api/schedules`, dll

### 2. Endpoint yang Tersedia

Sekarang endpoint API adalah:

#### Public Routes
- `POST /api/login` - Login dengan employee_id dan password

#### Protected Routes (require Bearer token)
- `POST /api/logout` - Logout
- `GET /api/user` - Get user info
- `GET /api/schedules` - Get jadwal user (worker only)
- `POST /api/reports` - Submit laporan (worker only)
- `GET /api/reports` - Get feed aktivitas (all authenticated users)
- `GET /api/attendance/today` - Get status absensi hari ini
- `POST /api/attendance/clock-in` - Clock in dengan foto selfie
- `POST /api/attendance/clock-out` - Clock out dengan foto selfie
- `PATCH /api/issues/{id}/status` - Update status issue
- `POST /api/leave-submissions` - Submit pengajuan cuti/izin

## Cara Menjalankan Backend

### Prasyarat
1. **PHP dengan ekstensi ZIP** - Diperlukan untuk Filament
   ```bash
   # Cek apakah zip extension aktif
   php -m | findstr zip
   ```
   
   Jika belum ada, aktifkan di `php.ini`:
   - Buka `C:\laragon\bin\php\php-8.3.30-Win32-vs16-x64\php.ini`
   - Cari `extension=zip`
   - Hapus `;` di depannya (uncomment)
   - Restart Laragon

2. **Composer**
3. **Database MySQL**

### Langkah-langkah Setup

```bash
cd d:\Semester6\sobm\backend

# 1. Install dependencies (setelah ZIP extension aktif)
composer install

# 2. Copy environment file
copy .env.example .env

# 3. Generate app key
php artisan key:generate

# 4. Setup database di .env
# Edit DB_DATABASE, DB_USERNAME, DB_PASSWORD

# 5. Run migrations
php artisan migrate

# 6. Seed data (opsional)
php artisan db:seed

# 7. Generate schedules (jika diperlukan)
php artisan schedules:generate

# 8. Jalankan server
php artisan serve
```

Server akan berjalan di: `http://127.0.0.1:8000`

### Untuk Development dengan Ngrok (agar bisa diakses dari HP)

```bash
# Di terminal 1: Jalankan Laravel
php artisan serve

# Di terminal 2: Jalankan ngrok
ngrok http 8000
```

Copy URL ngrok (misal: `https://xxxx.ngrok-free.app`) dan update di:
- `frontend/lib/app_config.dart` → ubah `_defaultApiBaseUrl`

## Frontend Configuration

File: `frontend/lib/app_config.dart`

```dart
static const String _defaultApiBaseUrl = environment == 'prod'
    ? 'https://production.sobm.api/api'
    : 'https://YOUR-NGROK-URL.ngrok-free.app/api'; // Update ini
```

**PENTING:** URL harus berakhiran `/api` (TANPA `/v1`)

### Testing API Endpoint

```bash
# Test login
curl -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "employee_id": "EMP001",
    "password": "password123"
  }'

# Test schedules (dengan token)
curl -X GET http://127.0.0.1:8000/api/schedules \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Troubleshooting

### Error: "Route not found" atau 404
**Penyebab:** Routes cache belum di-clear
**Solusi:**
```bash
php artisan route:clear
php artisan config:clear
php artisan cache:clear
```

### Error: "SQLSTATE connection refused"
**Penyebab:** Database belum running atau konfigurasi salah
**Solusi:**
1. Start MySQL di Laragon
2. Cek `.env`: DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME, DB_PASSWORD
3. Jalankan `php artisan migrate`

### Error: "ext-zip is missing"
**Penyebab:** PHP extension zip belum aktif
**Solusi:**
1. Edit `php.ini`
2. Uncomment `extension=zip`
3. Restart server/Laragon

### Frontend masih error 404 setelah perbaikan
**Solusi:**
1. Pastikan backend sudah running: `php artisan serve`
2. Pastikan routes sudah di-update (tanpa prefix v1)
3. Clear cache backend: `php artisan route:clear`
4. Restart aplikasi Flutter:
   ```bash
   # Stop aplikasi
   # Lalu run ulang
   flutter run
   ```

## Verifikasi Routes

Setelah backend running, cek daftar routes:

```bash
php artisan route:list --path=api
```

Output harus menunjukkan:
```
POST   api/login
GET    api/schedules
POST   api/reports
GET    api/reports
...
```

BUKAN:
```
POST   api/v1/login
GET    api/v1/schedules
...
```

## Checklist Perbaikan

- ✅ Hapus `Route::prefix('v1')` dari `backend/routes/api.php`
- ✅ Frontend sudah menggunakan `/api/*` (tanpa `/v1`)
- ⚠️ Backend perlu install composer (butuh ZIP extension)
- ⚠️ Backend perlu setup database dan migration
- ⚠️ Update ngrok URL di `frontend/lib/app_config.dart`

## Next Steps

1. **Aktifkan ZIP extension di PHP**
2. **Install composer dependencies**: `composer install`
3. **Setup database**: Edit `.env` dan `php artisan migrate`
4. **Jalankan backend**: `php artisan serve`
5. **Update ngrok URL** di frontend config
6. **Test aplikasi** dari Flutter: `flutter run`

---

**Tanggal Perbaikan:** January 2025  
**File yang Diubah:** `backend/routes/api.php`  
**Status:** ✅ Routes sudah diperbaiki, ⚠️ Backend perlu setup
