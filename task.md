# Task — SOBM (per Milestone)

Status: ✅ selesai · 🔲 belum dikerjakan. Setiap milestone dipecah menjadi
task **Backend** dan **Frontend** secara terpisah.

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
- 🔲 Tambah scheduled job/command untuk otomatis menandai status `Alpa`
  saat user tidak clock-in sama sekali.
- 🔲 Update `schedules:generate` (round-robin) agar mempertimbangkan user
  yang sedang cuti/izin.
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
- 🔲 Putuskan struktur penyimpanan foto (kolom langsung vs tabel `media`
  polymorphic) sebelum kebutuhan multi-foto per laporan muncul.
- 🔲 Putuskan apakah `reports` menyimpan referensi langsung ke
  `checkpoints`/`areas` atau tetap join lewat `schedules`.
- 🔲 Evaluasi kebijakan arsip data operasional secara keseluruhan.

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
