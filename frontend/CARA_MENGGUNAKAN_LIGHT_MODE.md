# Cara Menggunakan Fitur Light Mode

## Langkah-langkah Mengakses Toggle Light Mode:

### 1. Buka Aplikasi SOBM
- Login dengan kredensial Anda
- Anda akan masuk ke halaman Home (Dashboard)

### 2. Navigasi ke Halaman Profile
- Lihat **Bottom Navigation Bar** di bagian paling bawah layar
- Anda akan melihat 4 tombol navigasi:
  - 🏠 **Home**
  - 📊 **Monitoring**
  - 📋 **Reports**
  - 👤 **Profile** (atau **Admin** jika Anda admin)
  
- **TAP tombol paling kanan** (icon 👤 Profile)

### 3. Scroll ke Bagian Pengaturan
Setelah masuk ke halaman Profile, Anda akan melihat:
- Header dengan avatar dan informasi user
- Section "Informasi Akun" (ID Pegawai, Email, dll)
- **Section "Pengaturan"** ← SCROLL KE SINI

### 4. Temukan Toggle Light Mode
Di bawah tulisan **"Pengaturan"**, Anda akan melihat:

```
╔════════════════════════════════════╗
║  🌓  Mode Terang                   ║
║      Aktif/Nonaktif         [🔘]  ║
╚════════════════════════════════════╝
```

**Tampilan Toggle:**
- Icon matahari/bulan (🌓) di sebelah kiri
- Text "Mode Terang" 
- Status "Aktif" (jika light mode ON) atau "Nonaktif" (jika OFF)
- Switch toggle di sebelah kanan

### 5. Gunakan Toggle
- **TAP toggle switch** di sebelah kanan
- Aplikasi akan **langsung berubah** dari mode gelap ke terang atau sebaliknya
- **TIDAK PERLU RESTART** aplikasi

---

## Posisi Toggle di Halaman Profile

```
╔══════════════════════════════════════════╗
║  Profile Page (Scroll ke bawah)         ║
╠══════════════════════════════════════════╣
║                                          ║
║  [Avatar Gambar]                         ║
║  Nama Pengguna                           ║
║  [Role Badge]                            ║
║                                          ║
║  Informasi Akun                          ║
║  ├─ ID Pegawai                           ║
║  ├─ Email                                ║
║  ├─ Perusahaan                           ║
║  └─ Bergabung Sejak                      ║
║                                          ║
║  ⬇️ SCROLL KE SINI ⬇️                   ║
║                                          ║
║  Pengaturan                              ║
║  ┌──────────────────────────────┐       ║
║  │ 🌓 Mode Terang      [TOGGLE] │  ← INI║
║  │    Aktif/Nonaktif            │       ║
║  └──────────────────────────────┘       ║
║  ┌──────────────────────────────┐       ║
║  │ 🔒 Ubah Password        →    │       ║
║  └──────────────────────────────┘       ║
║  ┌──────────────────────────────┐       ║
║  │ 👤 Edit Profil          →    │       ║
║  └──────────────────────────────┘       ║
║  ┌──────────────────────────────┐       ║
║  │ ☁️ Antrian Offline      →    │       ║
║  └──────────────────────────────┘       ║
║  ┌──────────────────────────────┐       ║
║  │ ℹ️ Tentang Aplikasi      →    │       ║
║  └──────────────────────────────┘       ║
║                                          ║
║  [TOMBOL KELUAR]                         ║
║                                          ║
╚══════════════════════════════════════════╝
```

---

## Troubleshooting

### ❌ "Saya tidak melihat toggle di halaman Profile"

**Solusi:**
1. Pastikan Anda sudah **scroll ke bawah** di halaman Profile
2. Toggle berada di bawah section "Informasi Akun"
3. Cari tulisan **"Pengaturan"** dengan font besar
4. Toggle ada tepat di bawah tulisan "Pengaturan"

### ❌ "Toggle tidak bekerja/tidak berubah"

**Solusi:**
1. **Restart aplikasi** (close dan buka ulang)
2. Jalankan: `flutter clean` lalu `flutter pub get`
3. Jalankan ulang aplikasi: `flutter run`

### ❌ "Aplikasi masih mode gelap meskipun toggle ON"

**Cek:**
1. Pastikan toggle menunjukkan status "Aktif"
2. Aplikasi harus berubah **instantly** saat Anda tap toggle
3. Jika tidak berubah, ada masalah dengan ThemeProvider

---

## Cara Test Manual

### Test 1: Default Light Mode
1. **Install aplikasi fresh** (atau clear data)
2. Login
3. **Aplikasi harus tampil dalam LIGHT MODE** (background putih/terang)

### Test 2: Toggle Works
1. Buka Profile page
2. Scroll ke "Pengaturan"
3. Tap toggle Mode Terang
4. **Aplikasi langsung berubah ke dark mode** (background gelap)
5. Tap toggle lagi
6. **Aplikasi kembali ke light mode**

### Test 3: Persistence
1. Set toggle ke dark mode
2. **Close aplikasi** sepenuhnya
3. Buka aplikasi lagi
4. **Dark mode harus tetap aktif**
5. Begitu juga sebaliknya untuk light mode

---

## Cara Running Aplikasi untuk Testing

```bash
cd d:\Semester6\sobm\frontend

# Clean build (jika ada masalah)
flutter clean
flutter pub get

# Run di device/emulator
flutter run

# Atau build APK untuk install di HP
flutter build apk
```

APK akan ada di: `build/app/outputs/flutter-apk/app-release.apk`

---

## Catatan Penting

✅ **Light mode adalah DEFAULT** - Aplikasi akan buka dalam light mode pertama kali

✅ **Toggle langsung bekerja** - Tidak perlu restart aplikasi

✅ **Preference tersimpan** - Pilihan Anda akan diingat meskipun aplikasi ditutup

✅ **Visible untuk semua role** - Worker, Admin, OSB, Resepsionis, dll semua bisa akses

---

## Jika Masih Belum Terlihat

Coba langkah ini:

```bash
# 1. Stop aplikasi yang running
# 2. Clean build
cd d:\Semester6\sobm\frontend
flutter clean

# 3. Get dependencies
flutter pub get

# 4. Run dengan rebuild
flutter run
```

Atau jika pakai hot reload, coba:
- Press `R` di terminal untuk hot reload
- Press `Shift+R` untuk full restart

---

**File Updated:**
- ✅ `lib/theme_notifier.dart` - Default changed to light mode
- ✅ `lib/profile_page.dart` - Toggle added with better UI
- ✅ `lib/main.dart` - ThemeProvider integrated

**Tanggal Update:** January 2025
