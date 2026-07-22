# Kekurangan Backend

Daftar ini dibuat berdasarkan migration, model, controller, konfigurasi, dan
test yang ada di `backend`.

## Prioritas tinggi

1. **Kredensial development harus dikelola per environment.** Seeder sekarang
   mewajibkan `SEEDER_DEFAULT_PASSWORD`; secret tersebut tetap harus diatur
   melalui secret manager pada deployment.
2. **Otorisasi admin panel belum granular sepenuhnya.** Policy resource sudah
   tersedia, tetapi pembatasan kemampuan viewer perlu terus diperiksa untuk
   setiap resource baru.
3. **Cakupan test domain dan API belum lengkap.** Alur utama login, role access,
   geolocation, dan submission sudah diuji, tetapi masih perlu test khusus untuk
   seluruh endpoint serta kondisi concurrency.

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
