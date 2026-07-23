# CLAUDE.md — Konteks Proyek SOBM

Dokumen ini memberi konteks kerja untuk AI coding assistant (Claude Code) saat
membantu pengembangan SOBM. Baca bersama `erd.md` (skema data) dan `task.md`
(daftar tugas per milestone).

## Ringkasan Proyek

SOBM adalah aplikasi monitoring operasional berbasis lokasi untuk pekerja
lapangan: absensi, check-in checkpoint, upload foto kondisi lokasi, laporan
pekerjaan, dan feed aktivitas bersama antar-pekerja.

## Stack

- **Backend**: Laravel 13, PHP 8.3, Laravel Sanctum (token API), Filament
  (admin panel).
- **Frontend**: Flutter (aplikasi mobile pekerja).
- **Database**: `users`, `areas`, `checkpoints`, `task_categories`,
  `schedules`, `reports`, `issues`, `attendances`.

## Perintah Validasi

Backend:

```powershell
cd backend
php artisan test
```

Frontend:

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
```

## Role & Akses (penting untuk otorisasi/policy)

| Role | Backend (Filament) | Mobile: jadwal & laporan | Mobile: absensi | Mobile: feed aktivitas |
| --- | --- | --- | --- | --- |
| Admin | Akses penuh (CRUD) — satu-satunya role dengan akses backend | - | Ya | Ya (baca) |
| Viewer | Read-only sesuai policy | - | - | - |
| Housekeeping | Tidak ada | Ya, terikat jadwal | Ya | Ya (baca) |
| Teknisi | Tidak ada | Ya, terikat jadwal | Ya | Ya (baca) |
| Security | Tidak ada | Ya, terikat jadwal | Ya (2 shift 12 jam) | Ya (baca) |
| OSB | Tidak ada | Ya, **tanpa** terikat jadwal (kapan saja) | Ya | Ya (baca) |
| Resepsionis | Tidak ada | Ya, **tanpa** terikat jadwal (kapan saja) | Ya | Ya (baca) |
| BM | Tidak ada | Tidak mengirim laporan | Ya | Ya (baca) |
| User | Tidak ada | Tidak ada akses sama sekali | Tidak ada | Ya (baca-saja, satu-satunya akses) |

Aturan otorisasi kunci:

- Hanya **Admin** yang boleh mengakses/mengubah data lewat Filament. **Viewer**
  hanya baca. Role lain tidak punya akun Filament sama sekali.
- **OSB** dan **Resepsionis**: `POST /api/reports` tanpa `schedule_id` wajib;
  validasi kepemilikan jadwal/tanggal/status/radius checkpoint **tidak**
  berlaku untuk mereka. Validasi yang tetap berlaku: `work_description`
  wajib, format & ukuran foto, kondisi laporan.
- **Housekeeping, Teknisi, Security**: laporan wajib terikat `schedule_id`,
  lolos validasi kepemilikan jadwal, tanggal, status `pending`, dan radius
  checkpoint.
- **Admin** dan **BM**: absensi saja, tidak ada jadwal patroli/checkpoint,
  tidak mengirim laporan.
- **User**: role paling terbatas — hanya boleh memanggil `GET /api/reports`
  (feed). Middleware/policy harus menolak akses ke endpoint schedules,
  reports (POST), dan attendance untuk role ini.

## Aturan Bisnis Kunci (jangan dilanggar saat implementasi)

- Satu jadwal (`schedule`) hanya boleh punya satu `report` (`reports.schedule_id`
  unik).
- Satu user hanya boleh punya satu `attendance` per tanggal (unique index
  `user_id` + `date`).
- Foto laporan: jpeg/jpg/png/webp, maksimal 2 MB, disimpan di disk `public`.
- Kondisi laporan `Ada Kendala` otomatis membuat satu `issue` terkait.
- Ambang keterlambatan absensi: 15 menit dari jam masuk role terkait →
  status `Terlambat`; sebelum/sampai ambang → `Hadir`.
- Clock-out hanya valid setelah clock-in di hari yang sama.
- Jam kerja & hari libur berbeda per role (lihat tabel jam kerja di
  dokumentasi proyek) — jangan pakai satu jam kerja global untuk semua role.
- Pembagian user pada `schedules:generate` memakai round-robin.

## Hal yang Perlu Hati-hati (gap terbuka, belum final)

- Shift Security lintas tengah malam (20:00-08:00) — belum jelas bagaimana
  `attendances (user_id, date)` menangani clock-in/out di dua tanggal kalender
  berbeda. Jangan asumsikan solusi tanpa konfirmasi.
- Belum ada liveness detection/face-matching pada selfie absensi, dan belum
  ada anti-spoofing GPS — jangan anggap validasi lokasi sebagai sumber
  kebenaran yang kuat.
- Radius checkpoint berbasis GPS horizontal tidak bisa membedakan lantai di
  gedung yang sama.
- Belum ada manajemen cuti/izin — user yang izin resmi berisiko otomatis
  `Alpa`.
- Belum ada rate limiting / account lockout pada login dan pengiriman
  laporan.
- Scope feed untuk role **User** (semua area vs area tertentu) belum
  diputuskan.

## Konvensi & Keamanan

- Jangan pernah menaruh secret (password seeder, API key, dsb.) di source
  control. Password seeding dibaca dari `SEEDER_DEFAULT_PASSWORD` di `.env`.
- Semua endpoint API (kecuali login) wajib pakai header
  `Authorization: Bearer <sanctum-token>`.
- Saat menambah role atau endpoint baru, selalu update policy Filament dan
  middleware/gate di sisi API — jangan hanya menambah UI di Flutter.
- Sebelum mengubah skema `attendances`/`schedules`/`reports`, cek `erd.md`
  untuk constraint yang sudah ada (unique index, foreign key) agar migrasi
  tidak melanggar data existing.

## Referensi

- `erd.md` — struktur entitas, relasi, dan constraint database.
- `task.md` — daftar tugas dipecah per milestone, backend & frontend
  terpisah.
