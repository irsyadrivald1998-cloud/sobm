# Task dan Gambaran Project

## Tentang project

Project ini adalah aplikasi monitoring dan pelaporan operasional berbasis
lokasi. Aplikasi digunakan oleh pekerja lapangan untuk melihat jadwal tugas,
melakukan check-in di checkpoint tertentu, mengunggah foto kondisi lokasi, dan
melaporkan kendala.

Project terdiri dari:

- **Backend**: Laravel 13, PHP 8.3, Sanctum, dan Filament.
- **Frontend**: Flutter untuk aplikasi mobile pekerja.
- **Database**: Migration domain menggunakan tabel users, areas, checkpoints,
  task_categories, schedules, reports, dan issues.

## Aktor project

| Aktor | Fungsi |
| --- | --- |
| Admin | Mengelola user, area, checkpoint, kategori tugas, jadwal, laporan, dan issue melalui Filament. |
| Viewer | Dapat mengakses admin panel sesuai konfigurasi saat ini, tetapi pembatasan resource belum granular. |
| Housekeeping | Melihat jadwal dan mengirim laporan check-in. |
| Teknisi | Melihat jadwal dan mengirim laporan check-in. |
| Security | Melihat jadwal dan mengirim laporan check-in. |

## Alur project

### 1. Persiapan data oleh admin

Admin masuk ke `/admin`, kemudian menyiapkan:

1. User beserta `employee_id`, nama, password, dan role.
2. Area operasional.
3. Checkpoint dengan koordinat dan radius validasi.
4. Kategori tugas berdasarkan role pekerja.
5. Jadwal tugas untuk user, checkpoint, kategori tugas, tanggal, dan waktu.

### 2. Pembuatan jadwal

Command `php artisan schedules:generate` dapat membuat jadwal berdasarkan
waktu saat command dijalankan:

- Housekeeping: setiap dua jam pada 08:00-18:00.
- Teknisi: setiap tiga jam pada 08:00-18:00.
- Security: setiap jam pada 22:00-05:00.

Jadwal dibagikan secara round-robin kepada user dengan role yang sesuai.
Command ini harus dijalankan oleh scheduler atau proses terjadwal agar
pembuatan jadwal berjalan otomatis.

### 3. Login pekerja

Frontend mengirim `employee_id` dan password ke:

```text
POST /api/login
```

Backend memvalidasi kredensial dan mengembalikan token Sanctum. Frontend
menyimpan token untuk request berikutnya.

### 4. Melihat jadwal

Frontend mengirim token ke:

```text
GET /api/schedules
```

Backend hanya mengembalikan jadwal milik user yang sedang login, beserta data
checkpoint dan task category.

### 5. Check-in dan pengiriman laporan

Pekerja memilih jadwal hari ini, mengambil lokasi dan foto, lalu mengirim
multipart request ke:

```text
POST /api/reports
```

Backend memeriksa:

1. User telah login dan memiliki role pekerja.
2. Jadwal benar-benar milik user tersebut.
3. Jadwal belum selesai dan belum memiliki laporan.
4. Tanggal jadwal sama dengan tanggal saat ini.
5. Jarak lokasi check-in berada di dalam radius checkpoint.
6. Foto dan status kondisi memenuhi validasi.

Jika validasi berhasil:

- Foto disimpan pada disk `public`.
- Record `reports` dibuat.
- Status `schedules` diubah menjadi `completed`.
- Jika kondisi `Ada Kendala`, record `issues` dibuat.

### 6. Monitoring oleh admin

Admin melihat laporan dan kendala melalui Filament. Laporan menampilkan
pekerja, checkpoint, waktu check-in, koordinat, foto, kondisi, catatan, dan
deskripsi kendala bila tersedia.

## Batasan project saat ini

### Batasan fitur

- API mobile hanya menyediakan login, logout, data user, daftar jadwal, dan
  pengiriman laporan.
- Belum ada endpoint mobile untuk mengubah atau menyelesaikan issue.
- Belum ada notifikasi untuk jadwal baru, laporan gagal, atau kendala.
- Jadwal hanya memiliki status `pending` dan `completed`.
- Sistem belum mendukung penjadwalan berbasis shift yang dapat dikonfigurasi
  penuh dari admin.
- Satu jadwal hanya dapat memiliki satu laporan.
- Satu laporan secara model hanya dapat memiliki satu issue.

### Batasan operasional

- Check-in hanya dapat dilakukan pada hari jadwal.
- Check-in dibatasi oleh koordinat checkpoint dan `radius_meter`.
- Foto dibatasi pada format jpeg, jpg, png, atau webp dengan ukuran maksimal
  2 MB.
- Pembagian jadwal menggunakan round-robin sederhana dan memilih kategori tugas
  pertama untuk role tersebut.
- Command generator tidak menjamin idempotensi pada kondisi concurrent tanpa
  unique constraint yang sesuai.

### Batasan keamanan

- Login memakai token Sanctum, tetapi migration
  `personal_access_tokens` belum ditemukan pada repository.
- Kredensial development `password123` masih dicantumkan pada seeder dan
  dokumentasi.
- Belum tersedia policy per-resource yang membatasi kemampuan admin dan
  viewer secara detail.
- Koordinat check-in berasal dari perangkat dan belum memiliki mekanisme
  anti-spoofing.
- Belum terlihat rate limiting khusus untuk login dan pengiriman laporan.

### Batasan kualitas dan deployment

- Test yang tersedia masih berupa test contoh Laravel; test API dan alur bisnis
  belum tersedia.
- README backend masih berupa template Laravel.
- Konfigurasi frontend memakai default base URL berupa alamat IP lokal.
- Belum ada dokumentasi resmi untuk scheduler, storage link, queue, backup,
  monitoring, dan deployment production.
- Penghapusan data parent menggunakan cascade dan berisiko menghapus histori
  schedule serta report.

## Task lanjutan yang disarankan

### Prioritas tinggi

- Tambahkan migration Sanctum dan verifikasi proses login pada database baru.
- Ganti kredensial default dengan secret development yang tidak disimpan di
  repository.
- Tambahkan test feature untuk login, role access, submit report, geolocation,
  dan duplicate submission.
- Terapkan policy Filament untuk admin dan viewer.

### Prioritas menengah

- Tambahkan unique constraint untuk mencegah duplikasi jadwal.
- Samakan constraint database dengan relasi `Report::issue()`.
- Validasi kesesuaian role user dan kategori tugas.
- Tambahkan workflow issue, audit penyelesaian, dan strategi arsip histori.
- Pisahkan konfigurasi base URL frontend dari source code.

### Prioritas rendah

- Tambahkan dokumentasi API dan deployment.
- Tambahkan notification dan monitoring.
- Evaluasi index komposit berdasarkan pola query produksi.
- Gunakan enum PHP atau tabel referensi untuk role dan status.
