# Kekurangan Backend

Daftar ini dibuat berdasarkan migration, model, controller, konfigurasi, dan
test yang ada di `backend`.

## Prioritas tinggi

1. **Migrasi token Sanctum tidak ada.** `AuthController::login()` memanggil
   `createToken()`, tetapi migration `personal_access_tokens` tidak ditemukan.
2. **Kredensial default disimpan di repository.** Seeder dan
   `LOGIN_CREDENTIALS.md` menggunakan password `password123`.
3. **Otorisasi admin panel terlalu luas.** `admin` dan `viewer` sama-sama dapat
   masuk panel, tetapi belum ada policy/per-resource authorization.
4. **Belum ada test domain atau API.** Alur login, role access, geolocation,
   submit ganda, cascade, dan pembuatan issue belum memiliki regression test.

## Prioritas menengah

5. **Integritas penugasan belum dijaga.** Role user dapat tidak sesuai dengan
   `task_categories.target_role`.
6. **Pembuatan jadwal rentan race condition dan duplikasi.** Command hanya
   melakukan pengecekan `exists()` sebelum insert.
7. **Kardinalitas issue tidak konsisten.** Model memakai `hasOne`, tetapi
   `issues.report_id` belum unique.
8. **Cascade delete dapat menghapus histori operasional.** Penghapusan user,
   checkpoint, atau kategori dapat menghapus schedule dan report.
9. **Workflow masih sederhana.** Schedule hanya memiliki `pending` dan
   `completed`; issue hanya memiliki flag `is_resolved`.
10. **Validasi numerik belum diperkuat di database.** Latitude, longitude, dan
    `radius_meter` belum memiliki check constraint.
11. **Lifecycle foto belum lengkap.** Database hanya menyimpan `photo_path`
    tanpa metadata atau mekanisme cleanup file.

## Prioritas rendah

12. **Enum tersebar di banyak tempat.** Role dan status diulang pada migration,
    middleware, form, seeder, dan command.
13. **Index query operasional belum eksplisit.** Pertimbangkan index komposit
    sesuai pola query setelah diukur pada data produksi.
14. **Dokumentasi API dan deployment belum memadai.** README masih template
    Laravel dan belum menjelaskan endpoint, storage, scheduler, queue, serta
    setup database.
