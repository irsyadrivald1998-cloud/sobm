# Task — Fitur Absensi SOBM

## Backend

- [x] Tambah method `history()` di `AttendanceController.php`
- [x] Tambah route `GET /attendance/history` di `api.php`
- [x] Fix `LeaveSubmissionController.php` agar sinkron dengan frontend
- [x] Buat migration baru untuk update tabel `leave_submissions` (tambah `start_date`, `end_date`, `reason`, buat `attachment_path` nullable)
- [x] Update model `LeaveSubmission.php` (fillable + casts)
- [x] Jalankan migration

## Frontend

- [x] Tambah method `getAttendanceHistory()` di `api_service.dart`
- [x] Redesign `attendance_page.dart` — tambah Clock In & Clock Out dengan alur GPS → Selfie → Konfirmasi → Kirim API
- [x] Tambah tab Riwayat di `attendance_page.dart` — picker bulan + list riwayat
- [x] Tambah card status absensi di `home_page.dart` (shortcut ke halaman absensi)
- [x] Tambah item navigasi Absensi di bottom nav `home_page.dart`

---

# Task — Fitur Foto Profil User

## Backend
- [ ] Buat migration untuk tambah kolom `photo_path` di tabel `users`
- [ ] Update model `User.php` (tambahkan `photo_path` ke fillable)
- [ ] Buat `ProfileController.php` untuk menangani update profil dan upload foto
- [ ] Tambahkan route API untuk update profil dan foto user di `api.php`
- [ ] Jalankan migration

## Frontend
- [ ] Update `api_service.dart` agar method `updateAvatar` dan `updateProfile` memanggil endpoint yang tepat
- [ ] Update `profile_page.dart` agar tombol "Edit Profil" membuka `EditProfilePage` dan memuat ulang data saat kembali
- [ ] Tampilkan foto profil/avatar di `profile_page.dart` dan `edit_profile_page.dart` (jika ada `photo_path`, ambil via URL, jika tidak tampilkan icon default)
- [ ] Implementasikan pemilihan foto dari galeri/kamera di `edit_profile_page.dart` menggunakan `image_picker` dan upload ke backend


## Milestone 0 — Fondasi (Selesai)

### Backend

- ✅ Migration awal & autentikasi Sanctum.
- ✅ `POST /api/login`, `POST /api/logout`, `GET /api/user`.
- ✅ `GET /api/schedules`.
- ✅ `POST /api/reports` (jadwal, foto, kondisi, deskripsi manual, catatan).
- ✅ Validasi geolocation checkpoint & pencegahan laporan ganda
  (`reports.schedule_id` unik).
- ✅ Policy Filament dasar untuk Admin dan Viewer.
- ✅ Absensi: `GET /api/attendance/today`, `POST /api/attendance/clock-in`,
  `POST /api/attendance/clock-out`.
- ✅ Feed aktivitas laporan lintas pekerja (`GET /api/reports`).
- ✅ Test feature: login, role access, laporan, geolocation.

### Frontend (Flutter)

- ✅ Alur login dengan `employee_id`.
- ✅ Tampilan jadwal pekerja.
- ✅ Form laporan: deskripsi manual, kondisi, upload foto, GPS checkpoint.
- ✅ Tampilan lantai dari data checkpoint.
- ✅ Alur absensi clock-in/clock-out dengan selfie & GPS kantor.
- ✅ Feed aktivitas (read-only, reload saat dibuka/refresh).

---

## Milestone 1 — Role & Akses (baru: OSB, Resepsionis, BM, User)

### Backend
 
- ✅ Migration + seeding role baru: `OSB`, `Resepsionis`, `BM`, `User` pada
  tabel `users`/`role`.
- ✅ Update `schedules:generate`:
  - Admin & BM: tidak menghasilkan jadwal patroli/checkpoint (hanya absensi).
  - User: tidak menghasilkan jadwal sama sekali (tidak absensi, tidak
    patroli).
  - OSB & Resepsionis: jadwal kerja 08:00-17:00 tanpa frekuensi checkpoint
    tetap.
- ✅ `POST /api/reports`: buat `schedule_id` nullable/opsional khusus role
  OSB & Resepsionis; lewati validasi kepemilikan jadwal/tanggal/status/radius
  untuk kedua role ini, tetap validasi `work_description`, format & ukuran
  foto, dan kondisi laporan.
- ✅ Middleware/policy baru untuk role **User**: hanya izinkan
  `GET /api/reports` (feed); tolak akses ke `GET /api/schedules`,
  `POST /api/reports`, dan seluruh endpoint `attendance/*`.
- ✅ Policy Filament: pastikan role Housekeeping, Teknisi, Security, OSB,
  Resepsionis, BM, dan User **tidak** punya akun/akses backend sama sekali;
  hanya Admin (penuh) dan Viewer (read-only).
- ✅ Update test feature untuk role access mencakup role-role baru
  (khususnya negative test: User ditolak di endpoint selain feed).

### Frontend

- ✅ Sesuaikan UI role OSB/Resepsionis: form laporan tanpa pemilihan jadwal
  wajib (opsional), tetap wajib deskripsi & foto.
- ✅ Buat mode UI untuk role **User**: hanya tampilkan halaman feed
  aktivitas; sembunyikan/nonaktifkan menu jadwal, laporan, dan absensi.
- ✅ Update pesan error/UX saat role User mencoba mengakses fitur yang tidak
  diizinkan (idealnya dicegah dari sisi navigasi, bukan hanya error API).

---

## Milestone 2 — Feed, Test Coverage, & UX Tambahan

### Backend

- ✅ Tambah polling atau realtime notification untuk aktivitas laporan baru.
- ✅ Tambah filter tanggal, role, checkpoint, dan status pada
  `GET /api/reports` bila dibutuhkan.
- ✅ Tambah pagination pada `GET /api/reports` (feed berpotensi berat saat
  data menumpuk).
- ✅ Lengkapi test feature: feed aktivitas, absensi, deskripsi pekerjaan,
  upload foto, dan akses antar-user (termasuk role User & OSB/Resepsionis).

### Frontend

- ✅ Implementasi infinite scroll / pagination di halaman feed.
- ✅ Tambah filter UI (tanggal/role/checkpoint/status) di feed bila endpoint
  filter tersedia.
- ✅ Notifikasi in-app untuk aktivitas laporan baru (menyesuaikan mekanisme
  polling/realtime dari backend).
- ✅ **Light mode toggle**: Fitur toggle mode terang/gelap di halaman profile
  dengan default mode terang untuk seluruh aplikasi.
- ✅ **Sistem notifikasi**: Notification service dengan badge unread count di
  icon notifikasi, halaman daftar notifikasi dengan dismiss/delete, dan 
  integrasi dengan activity log untuk notifikasi aktivitas baru.

---

## Milestone 3 — Workflow Issue & Notifikasi Kendala

### Backend

- ✅ Definisikan lifecycle status `issues` (mis. `open`, `in-progress`,
  `resolved`).
- ✅ Tambah endpoint/aksi untuk update status issue & audit penyelesaian.
- ✅ Tambah notifikasi kendala ke Admin saat issue baru dibuat.

### Frontend

- ✅ Tampilkan status issue di Filament (Admin) dan/atau di feed mobile.
- ✅ (Jika relevan) UI konfirmasi/laporan tindak lanjut issue di sisi
  pekerja.

---

## Milestone 4 — Keamanan & Validasi Lapangan

### Backend

- ✅ Tambah rate limiting & account lockout untuk `POST /api/login` dan
  `POST /api/reports` guna mencegah brute-force.
- 🔲 Evaluasi signed URL / access control untuk foto laporan & selfie
  (saat ini disimpan di disk `public`).
- 🔲 Riset & implementasi opsi anti-spoofing GPS untuk absensi dan laporan.
- 🔲 Riset opsi liveness detection / face-matching selfie terhadap foto
  referensi user.
- 🔲 Tentukan strategi token expiry/refresh Sanctum & kebijakan multi-device
  login.

### Frontend

- ✅ Implementasi kompresi foto sebelum upload (mengurangi risiko gagal/
  lambat pada jaringan lapangan buruk).
- ✅ Sesuaikan alur selfie/kamera bila liveness detection ditambahkan di
  backend (UI siap, tinggal integrasi backend).
- ✅ Tambah offline support untuk absensi, check-in, dan laporan saat sinyal
  buruk (prioritas tinggi untuk shift Security malam hari) — perlu strategi
  queue & sync saat online kembali.

---

## Milestone 5 — Alur Bisnis: Shift Malam, Cuti, & Status Alpa

### Backend

- 🔲 Putuskan & implementasikan definisi tanggal absensi untuk shift
  Security yang melewati tengah malam (apakah `date` = tanggal mulai shift
  atau tanggal kalender saat clock-in/out).
- ✅ Bangun modul manajemen cuti/izin/sakit (Upload surat izin/sakit); pastikan user berstatus izin
  resmi tidak otomatis menjadi `Alpa`.
- ✅ Tambah command untuk otomatis menandai status `Alpa` saat user tidak
  clock-in sama sekali (MarkAlpaCommand sudah dibuat).
- 🔲 Tambah scheduled job (cron/scheduler) untuk menjalankan MarkAlpaCommand
  setiap hari pada waktu yang ditentukan.
- ✅ Update `schedules:generate` (round-robin) agar mempertimbangkan user
  yang sedang cuti/izin (sudah diimplementasi dengan whereDoesntHave leaveSubmissions).
- 🔲 Tambah mekanisme forgot/reset password untuk pekerja lapangan (saat
  ini hanya mengandalkan password hasil seeding).

### Frontend

- ✅ UI pengajuan cuti/izin/sakit (jika modul backend sudah tersedia).
- ✅ UI forgot/reset password.
- ✅ Sesuaikan tampilan status kehadiran bila ada status baru terkait cuti
  (mis. `Izin`, `Sakit`) selain `Hadir`/`Terlambat`/`Alpa`.

---

## Milestone 6 — Database & Skalabilitas

### Backend

- ✅ Tambah unique constraint & transaksi pada proses generate jadwal untuk
  mencegah duplikasi saat berjalan bersamaan.
- ✅ Simpan state round-robin (`schedules:generate`) di database, bukan
  hanya variable runtime.
- ✅ Tambah soft delete pada `schedules`, `reports`, `attendances`.
- ✅ Tambah index: `schedules (user_id, date, status)` dan
  `reports (created_at)`.
- ✅ Putuskan struktur penyimpanan foto: **Gunakan kolom langsung untuk sekarang**
  (reports.photo_path, attendances.clock_in_photo_path/clock_out_photo_path,
  leave_submissions.attachment_path). Akan migrasi ke tabel `media` polymorphic
  bila kebutuhan multi-foto per laporan muncul di masa depan.
- ✅ Putuskan struktur referensi `reports`: **Tetap join lewat `schedules`**
  (reports.schedule_id -> schedules.checkpoint_id -> checkpoints.area_id).
  Struktur ini menjaga integritas data dan konsistensi dengan jadwal. Untuk
  role OSB/Resepsionis yang bisa submit tanpa jadwal, schedule_id nullable
  dan tetap bisa diisi bila ada checkpoint terkait.
- ✅ Evaluasi kebijakan arsip data operasional: **Gunakan soft delete untuk
  sekarang** (schedules, reports, attendances sudah soft delete). Implementasi
  archival/backup ke storage terpisah atau cold storage bila data sudah
  mencapai threshold tertentu (mis. 1 tahun atau 1 juta records).

### Frontend

- ✅ Tidak ada task frontend langsung; pastikan tim frontend diberi tahu
  bila ada perubahan kontrak API akibat perubahan skema (mis. field foto
  baru, soft-delete flag yang memengaruhi tampilan histori).
  
  **Note:** Frontend sudah siap menangani perubahan skema dengan error handling
  yang baik dan struktur yang fleksibel.

---

## Milestone 7 — Infrastruktur & Observability

### Backend

- ✅ Tambah API versioning (`/api/v1/`) untuk mengantisipasi perubahan
  breaking.
- 🔲 Tambah observability: logging terstruktur, error tracking, monitoring
  uptime.

### Frontend

- ✅ Pisahkan base URL Flutter dari source code ke konfigurasi environment
  (mendukung penambahan versi API `/` di atas tanpa hardcode).
- ✅ Tambah error tracking sisi mobile (mis. crash reporting) agar selaras
  dengan observability backend.
