# Login Credentials

## Admin Panel Login

Aplikasi ini menggunakan **Employee ID** untuk login, bukan email.

### Kredensial Login

Password akun hasil seeding dibaca dari `SEEDER_DEFAULT_PASSWORD` di file `.env`.
Jangan menyimpan nilai password tersebut di repository atau membagikannya melalui
dokumentasi.

#### Admin
- **Employee ID**: `admin_001`
- **Password**: Nilai `SEEDER_DEFAULT_PASSWORD`
- **Role**: Admin
- **Nama**: Super Admin

#### Housekeeping
- **Employee ID**: `hk_001`
- **Password**: Nilai `SEEDER_DEFAULT_PASSWORD`
- **Role**: Housekeeping
- **Nama**: Budi Housekeeping

## Cara Login

1. Buka browser dan akses: `http://localhost:8000/admin/login`
2. Masukkan **Employee ID** (bukan email)
3. Masukkan **Password**
4. Klik tombol Login

## Pesan Error

Jika Employee ID atau password salah, akan muncul pesan:
**"Employee ID atau password salah."**

## Troubleshooting

Jika tidak bisa login:

1. **Clear cache**:
   ```bash
   php artisan optimize:clear
   ```

2. **Pastikan database sudah di-seed**:
   ```bash
   $env:SEEDER_DEFAULT_PASSWORD = '<isi-secret-development>'
   php artisan migrate:fresh --seed
   ```

3. **Cek apakah user ada di database**:
   ```bash
   php artisan tinker --execute="echo App\Models\User::count();"
   ```

4. **Test authentication manual**:
   ```bash
   php artisan tinker --execute="echo Auth::attempt(['employee_id' => 'admin_001', 'password' => env('SEEDER_DEFAULT_PASSWORD')]) ? 'SUCCESS' : 'FAILED';"
   ```

## Catatan Teknis

- Field login menggunakan `employee_id` (bukan `email`)
- Password di-hash menggunakan bcrypt
- Authentication menggunakan Laravel's default guard dengan custom credentials
- Filament v5.x digunakan untuk admin panel
