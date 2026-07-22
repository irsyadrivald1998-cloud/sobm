# Rencana Fitur Absensi (Attendance Feature)

Dokumen ini berisi ketentuan, arsitektur database, spesifikasi API, dan integrasi admin panel untuk fitur Absensi Pekerja Lapangan pada aplikasi SOBM.

---

## 1. Alur Bisnis Absensi

Pekerja wajib melakukan absensi masuk (Clock In) sebelum mulai bekerja dan absensi keluar (Clock Out) setelah menyelesaikan pekerjaannya hari itu.

### Ketentuan clock In (Absen Masuk)
1. **Validasi Geolocation**: Pekerja harus berada di dalam radius kantor utama atau area penugasan tertentu (misalnya, Radius 100 meter dari koordinat kantor pusat).
2. **Validasi Swafoto (Selfie)**: Pekerja wajib mengunggah foto wajah asli saat clock in untuk menghindari kecurangan.
3. **Catatan Keterlambatan & Toleransi**: Jam masuk standar adalah pukul 08:00 WIB. Diberikan batas toleransi keterlambatan selama 15 menit (hingga pukul 08:15 WIB). Jika clock in dilakukan setelah pukul 08:15 WIB, status absensi akan otomatis tercatat sebagai **Terlambat (Late)**. Jika clock in antara pukul 08:01 hingga 08:15 WIB, status tetap dianggap **Hadir (Present)**.

### Ketentuan Clock Out (Absen Keluar)
1. **Validasi Status**: Hanya bisa dilakukan jika pekerja sudah melakukan Clock In pada hari yang sama.
2. **Validasi Swafoto & Lokasi**: Pekerja wajib menyertakan foto dan lokasi saat keluar.
3. **Penyelesaian Otomatis**: Jika pekerja lupa clock out hingga pergantian hari (pukul 00:00 WIB), status absensi hari tersebut akan ditandai secara otomatis (misal: Clock Out terisi manual oleh admin atau status disesuaikan).

---

## 2. Rancangan Database (`attendances`)

Tabel baru `attendances` akan menyimpan log kehadiran harian pekerja:

| Nama Kolom | Tipe Data | Keterangan |
| --- | --- | --- |
| `id` | BigInt (PK) | Auto increment primary key |
| `user_id` | Foreign Key | Berelasi ke tabel `users` (cascade atau restrict) |
| `date` | Date | Tanggal absensi (format: YYYY-MM-DD) |
| `clock_in_time` | Time/Timestamp | Waktu absen masuk |
| `clock_out_time` | Time/Timestamp (Nullable) | Waktu absen keluar |
| `clock_in_latitude` | Decimal (10, 8) | Koordinat lintang saat masuk |
| `clock_in_longitude` | Decimal (11, 8) | Koordinat bujur saat masuk |
| `clock_out_latitude` | Decimal (10, 8) (Nullable) | Koordinat lintang saat keluar |
| `clock_out_longitude` | Decimal (11, 8) (Nullable) | Koordinat bujur saat keluar |
| `clock_in_photo_path` | String | Path penyimpanan foto absen masuk |
| `clock_out_photo_path` | String (Nullable) | Path penyimpanan foto absen keluar |
| `status` | Enum | Pilihan: `'Hadir'`, `'Terlambat'`, `'Alpa'` |
| `notes` | Text (Nullable) | Catatan tambahan dari pekerja |
| `created_at` | Timestamp | Waktu data dibuat |
| `updated_at` | Timestamp | Waktu data diperbarui |
| `deleted_at` | Timestamp (Nullable) | Soft delete field |

*Note: Ditambahkan composite unique index pada `[user_id, date]` agar satu user hanya bisa memiliki satu record absensi per hari.*

---

## 3. Spesifikasi API Endpoints

### A. Cek Status Absen Hari Ini
Melihat status apakah user sudah Clock In / Clock Out hari ini.
- **Endpoint**: `GET /api/attendance/today`
- **Headers**: `Authorization: Bearer <token>`
- **Response (Belum Absen)**:
  ```json
  {
    "status": true,
    "message": "Belum absen hari ini.",
    "data": null
  }
  ```
- **Response (Sudah Clock In)**:
  ```json
  {
    "status": true,
    "message": "Sudah absen masuk.",
    "data": {
      "id": 1,
      "date": "2026-07-22",
      "clock_in_time": "07:55:00",
      "clock_out_time": null,
      "status": "Hadir"
    }
  }
  ```

### B. Clock In (Absen Masuk)
- **Endpoint**: `POST /api/attendance/clock-in`
- **Headers**: `Authorization: Bearer <token>`
- **Request (Multipart/Form-Data)**:
  - `latitude`: `-0.94326885`
  - `longitude`: `100.35396392`
  - `photo`: `File (image, max 2MB)`
  - `notes`: `Catatan (Opsional)`
- **Response (Sukses)**:
  ```json
  {
    "status": true,
    "message": "Absen masuk berhasil.",
    "data": {
      "id": 1,
      "user_id": 3,
      "date": "2026-07-22",
      "clock_in_time": "07:55:00",
      "status": "Hadir"
    }
  }
  ```

### C. Clock Out (Absen Keluar)
- **Endpoint**: `POST /api/attendance/clock-out`
- **Headers**: `Authorization: Bearer <token>`
- **Request (Multipart/Form-Data)**:
  - `latitude`: `-0.94326885`
  - `longitude`: `100.35396392`
  - `photo`: `File (image, max 2MB)`
- **Response (Sukses)**:
  ```json
  {
    "status": true,
    "message": "Absen keluar berhasil.",
    "data": {
      "id": 1,
      "clock_out_time": "17:01:00"
    }
  }
  ```

---

## 4. Integrasi Admin Panel (Filament)

Kami akan membuat **`AttendanceResource`** di Filament untuk mempermudah Admin memonitor absensi:
- **Tabel Absensi**: Menampilkan nama karyawan, tanggal, jam masuk, jam keluar, status (Hadir/Terlambat), dan tombol cepat untuk melihat foto selfie.
- **Peta Koordinat**: Integrasi lokasi check-in/out di Google Maps atau OpenStreetMap.
- **Filter**: Filter berdasarkan rentang tanggal, status kehadiran, dan departemen/role karyawan.
