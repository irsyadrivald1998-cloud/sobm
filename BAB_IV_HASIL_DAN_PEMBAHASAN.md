BAB IV
HASIL DAN PEMBAHASAN

4.1 Implementasi Sistem

Tahap implementasi sistem merupakan lanjutan dari proses perancangan yang telah dilakukan sebelumnya. Pada tahap ini, seluruh rancangan sistem yang telah dibuat diwujudkan ke dalam bentuk aplikasi nyata yang dapat dijalankan dan digunakan oleh pengguna. Implementasi sistem bertujuan untuk memastikan bahwa sistem informasi yang dibangun dapat berfungsi sesuai dengan kebutuhan yang telah dianalisis dan dirancang.

Pada subbab ini akan dijelaskan proses penerapan Sistem Operasional Building Management (SOBM) berbasis mobile. Proses implementasi meliputi pembuatan antarmuka (interface) mobile menggunakan Flutter, pengkodean program backend menggunakan Laravel, serta integrasi dengan basis data MySQL untuk pengolahan data pengguna, jadwal patroli, laporan pekerjaan, kendala, dan absensi.

Selain itu, pada tahap ini juga ditampilkan hasil dari implementasi berupa tampilan sistem (user interface) yang mencerminkan fungsi-fungsi utama yang tersedia dalam aplikasi. Dengan adanya implementasi ini, diharapkan sistem yang dibangun mampu memberikan kemudahan dalam pengelolaan operasional gedung, meningkatkan efisiensi kerja, serta meminimalisir kesalahan yang terjadi pada sistem manual sebelumnya.

Penulis menyadari bahwa implementasi sistem ini masih memiliki keterbatasan sebagai prototype untuk tugas mata kuliah, sehingga kritik dan saran sangat diharapkan guna pengembangan sistem yang lebih baik di masa yang akan datang.

4.2 Tampilan Aplikasi

4.2.1 Desain Output

Perancangan output merupakan hal yang tidak dapat diabaikan, karena output atau keluaran yang dihasilkan harus mudah dipahami oleh setiap unsur manusia yang memerlukannya. Output adalah hasil keluaran sistem yang berbentuk informasi atau laporan yang dapat dilihat.

Adapun rancangan output dari sistem yang diusulkan adalah sebagai berikut:

1. Desain Laporan Data Pengguna

Gambar 4.1 Desain Laporan Data Pengguna

2. Desain Laporan Absensi

Gambar 4.2 Desain Laporan Data Absensi

3. Desain Laporan Jadwal Patroli

Gambar 4.3 Desain Laporan Jadwal Patroli

4. Desain Laporan Pekerjaan

Gambar 4.4 Desain Laporan Data Pekerjaan

5. Desain Laporan Kendala

Gambar 4.5 Desain Laporan Data Kendala

6. Desain Laporan Cuti dan Izin

Gambar 4.6 Desain Laporan Cuti dan Izin

7. Desain Dashboard Monitoring

Gambar 4.7 Desain Dashboard Monitoring Operasional

4.2.2 Desain Input

Perancangan input merupakan proses perancangan bentuk format layar untuk mengelola data dalam aplikasi. Perancangan input ini dapat dilihat pada gambar berikut:

1. Desain Login

Gambar 4.8 Desain Login

2. Desain Halaman Absensi Clock-In

Gambar 4.9 Desain Absensi Clock-In

3. Desain Halaman Absensi Clock-Out

Gambar 4.10 Desain Absensi Clock-Out

4. Desain Input Laporan Pekerjaan

Gambar 4.11 Desain Input Laporan Pekerjaan

5. Desain Input Laporan Kendala

Gambar 4.12 Desain Input Laporan Kendala

6. Desain Input Pengajuan Cuti

Gambar 4.13 Desain Input Pengajuan Cuti

7. Desain Halaman Jadwal Patroli

Gambar 4.14 Desain Halaman Jadwal Patroli

8. Desain Halaman Feed Aktivitas

Gambar 4.15 Desain Halaman Feed Aktivitas

9. Desain Halaman Profil Pengguna

Gambar 4.16 Desain Halaman Profil Pengguna

10. Desain Halaman Dashboard Admin

Gambar 4.17 Desain Halaman Dashboard Admin

4.3 Pengujian Sistem

Pengujian sistem dilakukan dengan tujuan untuk menjamin system yang dibangun sesuai dengan hasil analisa dan perancangan sehingga dapat dibuat satu kesimpulan akhir. Model atau cara pengujian pada system ini yaitu menggunakan pengujian model Black Box. Berikut hasil pengujian sebagai berikut:

1. Pengujian Login

Pengujian login pada sistem SOBM dilakukan untuk berbagai jenis pengguna sesuai dengan role yang telah ditentukan, yaitu Admin, Viewer, Petugas Lapangan (Housekeeping, Teknisi, Security), OSB, Resepsionis, BM, dan User. Setiap role memiliki hak akses yang berbeda sesuai dengan kebutuhan operasional gedung.

Tabel 4.1 Pengujian Login

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Mengosongkan semua isian login, lalu menekan tombol Login | Employee ID: (kosong)<br>Password: (kosong) | Sistem menolak akses login dan menampilkan pesan: Employee ID dan password wajib diisi. | Sukses |
| Mengisi employee_id atau password yang salah, lalu menekan tombol Login | Employee ID: 12345<br>Password: salah | Sistem menolak akses login dan menampilkan pesan: Employee ID atau password salah. | Sukses |
| Mengisi employee_id dan password yang benar, lalu menekan tombol Login | Employee ID: 12345<br>Password: password123 | Sistem menerima login dan mengarahkan ke dashboard sesuai role. | Sukses |

2. Pengujian Absensi Clock-In

Pengujian ini dilakukan untuk memastikan proses absensi clock-in dengan verifikasi GPS dan selfie dapat berjalan dengan baik.

Tabel 4.2 Pengujian Absensi Clock-In

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Melakukan clock-in tanpa izin GPS | Izin GPS: Ditolak | Sistem menampilkan pesan: Izin GPS wajib diberikan untuk absensi. | Sukses |
| Melakukan clock-in di luar radius kantor | Lokasi: Di luar radius kantor | Sistem menolak absensi dan menampilkan pesan: Lokasi tidak valid, berada di luar radius kantor. | Sukses |
| Melakukan clock-in dalam radius kantor tanpa selfie | Lokasi: Valid<br>Selfie: Tidak diambil | Sistem menolak absensi dan menampilkan pesan: Selfie wajib diambil. | Sukses |
| Melakukan clock-in dengan data lengkap dan valid | Lokasi: Valid<br>Selfie: Diambil<br>Waktu: Sebelum jam kerja | Sistem menyimpan absensi dengan status "Hadir" dan menampilkan pesan sukses. | Sukses |
| Melakukan clock-in terlambat | Lokasi: Valid<br>Selfie: Diambil<br>Waktu: Setelah jam kerja | Sistem menyimpan absensi dengan status "Terlambat" dan menampilkan pesan sukses. | Sukses |

3. Pengujian Absensi Clock-Out

Pengujian ini dilakukan untuk memastikan proses absensi clock-out dapat berjalan dengan baik.

Tabel 4.3 Pengujian Absensi Clock-Out

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Melakukan clock-out tanpa clock-in sebelumnya | Belum clock-in hari ini | Sistem menolak clock-out dan menampilkan pesan: Silakan clock-in terlebih dahulu. | Sukses |
| Melakukan clock-out dengan data valid | Sudah clock-in<br>Lokasi: Valid | Sistem menyimpan clock-out dan menampilkan pesan sukses. | Sukses |

4. Pengujian Laporan Pekerjaan

Pengujian ini dilakukan untuk memastikan proses pelaporan pekerjaan dengan foto dan lokasi dapat berjalan dengan baik.

Tabel 4.4 Pengujian Laporan Pekerjaan

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Melapor pekerjaan tanpa memilih jadwal | Jadwal: Tidak dipilih | Sistem menolak laporan dan menampilkan pesan: Pilih jadwal terlebih dahulu. | Sukses |
| Melapor pekerjaan tanpa foto | Foto: Tidak diunggah | Sistem menolak laporan dan menampilkan pesan: Foto dokumentasi wajib diunggah. | Sukses |
| Melapor pekerjaan tanpa deskripsi | Deskripsi: (kosong) | Sistem menolak laporan dan menampilkan pesan: Deskripsi pekerjaan wajib diisi. | Sukses |
| Melapor pekerjaan dengan data lengkap | Jadwal: Dipilih<br>Foto: Diunggah<br>Deskripsi: Diisi<br>Kondisi: Aman | Sistem menyimpan laporan dan menampilkan pesan sukses. | Sukses |
| Melapor pekerjaan dengan kondisi ada kendala | Kondisi: Ada Kendala<br>Deskripsi Kendala: Diisi | Sistem menyimpan laporan dan membuat kendala baru dengan status "Open". | Sukses |

5. Pengujian Laporan Kendala

Pengujian ini dilakukan untuk memastikan proses pelaporan dan update kendala dapat berjalan dengan baik.

Tabel 4.5 Pengujian Laporan Kendala

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Melapor kendala tanpa deskripsi | Deskripsi: (kosong) | Sistem menolak laporan dan menampilkan pesan: Deskripsi kendala wajib diisi. | Sukses |
| Melapor kendala dengan data valid | Deskripsi: AC tidak dingin<br>Area: Lobby | Sistem menyimpan kendala dengan status "Open" dan menampilkan pesan sukses. | Sukses |
| Update status kendala oleh Admin | Status: In Progress | Sistem mengupdate status kendala menjadi "In Progress". | Sukses |
| Update status kendala menjadi resolved | Status: Resolved | Sistem mengupdate status kendala menjadi "Resolved". | Sukses |

6. Pengujian Pengajuan Cuti

Pengujian ini dilakukan untuk memastikan proses pengajuan cuti dan izin dapat berjalan dengan baik.

Tabel 4.6 Pengujian Pengajuan Cuti

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Mengajukan cuti tanpa tanggal | Tanggal: (kosong) | Sistem menolak pengajuan dan menampilkan pesan: Tanggal cuti wajib diisi. | Sukses |
| Mengajukan cuti tanpa jenis cuti | Jenis: (kosong) | Sistem menolak pengajuan dan menampilkan pesan: Jenis cuti wajib dipilih. | Sukses |
| Mengajukan cuti dengan data valid | Tanggal: 01/07/2026<br>Jenis: Cuti<br>Lampiran: Diunggah | Sistem menyimpan pengajuan dengan status "Pending" dan menampilkan pesan sukses. | Sukses |
| Supervisor menyetujui cuti | Status: Pending → Disetujui | Sistem mengupdate status menjadi "Disetujui" dan mengecualikan user dari jadwal. | Sukses |
| Supervisor menolak cuti | Status: Pending → Ditolak | Sistem mengupdate status menjadi "Ditolak". | Sukses |

7. Pengujian Jadwal Patroli

Pengujian ini dilakukan untuk memastikan sistem dapat menampilkan jadwal patroli yang telah digenerate secara otomatis.

Tabel 4.7 Pengujian Jadwal Patroli

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Menampilkan jadwal hari ini | User: Petugas Lapangan | Sistem menampilkan jadwal patroli untuk hari ini sesuai role user. | Sukses |
| Menampilkan jadwal minggu ini | User: Petugas Lapangan | Sistem menampilkan jadwal patroli untuk minggu ini. | Sukses |
| Admin generate jadwal baru | Admin klik generate jadwal | Sistem menggenerate jadwal baru menggunakan algoritma round-robin. | Sukses |

8. Pengujian Feed Aktivitas

Pengujian ini dilakukan untuk memastikan sistem dapat menampilkan feed aktivitas rekan kerja secara real-time.

Tabel 4.8 Pengujian Feed Aktivitas

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Menampilkan feed aktivitas | User membuka halaman feed | Sistem menampilkan aktivitas rekan kerja (clock-in, laporan pekerjaan, dll.). | Sukses |
| Refresh feed aktivitas | User scroll ke bawah | Sistem memuat aktivitas terbaru secara real-time. | Sukses |

9. Pengujian Notifikasi

Pengujian ini dilakukan untuk memastikan sistem dapat mengirim notifikasi real-time.

Tabel 4.9 Pengujian Notifikasi

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Notifikasi saat rekan clock-in | Rekan melakukan clock-in | User menerima notifikasi bahwa rekan telah clock-in. | Sukses |
| Notifikasi saat ada kendala baru | Ada kendala baru dilaporkan | Admin menerima notifikasi kendala baru. | Sukses |
| Notifikasi saat cuti disetujui | Cuti disetujui supervisor | User menerima notifikasi bahwa cuti disetujui. | Sukses |

10. Pengujian Dashboard Admin

Pengujian ini dilakukan untuk memastikan dashboard admin dapat menampilkan informasi operasional secara menyeluruh.

Tabel 4.10 Pengujian Dashboard Admin

| Skenario Pengujian | Uji Kasus | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| Menampilkan dashboard admin | Admin membuka dashboard | Sistem menampilkan statistik kehadiran, laporan pekerjaan, kendala, dan cuti. | Sukses |
| Filter data berdasarkan tanggal | Admin memilih rentang tanggal | Sistem mengupdate data dashboard sesuai rentang tanggal yang dipilih. | Sukses |

4.4 Pembahasan

Berdasarkan hasil pengujian yang telah dilakukan terhadap Sistem Operasional Building Management (SOBM) berbasis mobile, maka diperoleh pembahasan sebagai berikut:

1. Analisis Hasil Pengujian

Pengujian sistem dilakukan untuk memastikan bahwa seluruh fungsi yang terdapat dalam sistem berjalan dengan baik sesuai dengan perancangan yang telah dibuat. Dari hasil pengujian, diketahui bahwa fitur-fitur utama seperti login, absensi dengan verifikasi GPS dan selfie, pelaporan pekerjaan, pelacakan kendala, pengajuan cuti, penjadwalan patroli, feed aktivitas, notifikasi real-time, dan dashboard monitoring dapat berjalan dengan baik tanpa mengalami kendala yang signifikan.

Setiap proses input, edit, hapus, dan pencarian data dapat dilakukan dengan lancar, serta data yang diinput tersimpan dengan baik di dalam database. Verifikasi GPS berfungsi dengan baik untuk memastikan kehadiran karyawan berada dalam radius kantor yang ditentukan. Hal ini menunjukkan bahwa sistem telah berhasil diimplementasikan sesuai dengan kebutuhan yang telah ditentukan sebelumnya.

2. Kesesuaian Sistem dengan Kebutuhan

Sistem informasi yang dibangun telah mampu menjawab permasalahan yang sebelumnya terjadi pada sistem manual atau semi-digital dalam operasional gedung. Proses pengolahan data yang sebelumnya dilakukan secara manual kini telah terkomputerisasi melalui aplikasi mobile sehingga menjadi lebih cepat dan efisien.

Selain itu, sistem juga telah mampu:

a. Mengelola absensi karyawan dengan verifikasi GPS dan selfie untuk mengurangi kecurangan
b. Mengelola penjadwalan patroli secara otomatis dan adil
c. Memproses pelaporan pekerjaan dengan dokumentasi foto yang terstruktur
d. Melacak kendala dengan sistem status penyelesaian
e. Mengelola cuti dan izin secara terintegrasi dengan absensi
f. Menyediakan notifikasi real-time untuk koordinasi yang lebih baik
g. Menyediakan dashboard monitoring untuk pengawasan operasional

Dengan demikian, sistem ini dinilai telah sesuai dengan kebutuhan pengguna dan tujuan penelitian.

3. Kelebihan Sistem

Adapun kelebihan dari sistem yang telah dibangun adalah sebagai berikut:

1. Sistem mampu mengelola data operasional gedung secara terintegrasi dalam satu database.
2. Proses absensi dengan verifikasi GPS dan selfie meningkatkan akurasi kehadiran.
3. Penjadwalan patroli otomatis menggunakan algoritma round-robin yang adil.
4. Pelaporan pekerjaan dengan dokumentasi foto terarsip dengan baik dan mudah dilacak.
5. Sistem pelacakan kendala dengan status penyelesaian mempermudah monitoring.
6. Notifikasi real-time meningkatkan koordinasi dan awareness karyawan.
7. Dashboard monitoring menyediakan visualisasi data operasional secara menyeluruh.
8. Aplikasi mobile memudahkan akses kapan saja dan dimana saja.
9. Tampilan sistem sederhana dan mudah digunakan (user friendly).

4. Kekurangan Sistem

Meskipun sistem telah berjalan dengan baik, masih terdapat beberapa kekurangan, antara lain:

1. Sistem masih berupa prototype dan belum diimplementasikan pada gedung nyata.
2. Sistem belum menyediakan fitur offline mode untuk akses tanpa internet.
3. Belum terdapat fitur chat atau komunikasi langsung antar karyawan.
4. Keamanan GPS masih dapat dikembangkan lebih lanjut untuk mencegah spoofing.
5. Sistem belum terintegrasi dengan sistem manajemen gedung lain yang mungkin sudah ada.
6. Belum terdapat fitur analitik lanjutan untuk prediksi kebutuhan operasional.

Kekurangan ini dapat menjadi bahan pengembangan sistem di masa yang akan datang.

5. Dampak Implementasi Sistem

Setelah sistem diterapkan (sebagai prototype), terdapat beberapa dampak positif yang diharapkan, yaitu:

1. Meningkatkan efisiensi kerja dalam pengelolaan operasional gedung.
2. Menghemat waktu dalam proses pencatatan dan pencarian data.
3. Meminimalisir kesalahan dalam pencatatan absensi dan pelaporan pekerjaan.
4. Meningkatkan akuntabilitas kinerja karyawan melalui sistem pelacakan yang terstruktur.
5. Mempercepat penyelesaian kendala dengan sistem monitoring status.
6. Mempermudah pihak manajemen dalam memperoleh laporan secara cepat dan akurat.
7. Meningkatkan koordinasi antar tim operasional melalui notifikasi real-time.
8. Menyediakan dashboard monitoring untuk pengambilan keputusan berbasis data.
