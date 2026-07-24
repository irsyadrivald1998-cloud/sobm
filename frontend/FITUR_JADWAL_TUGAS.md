# Fitur Jadwal Tugas Karyawan

## Overview
Fitur ini memungkinkan karyawan untuk:
1. ✅ Melihat jadwal tugas yang di-assign oleh admin
2. ✅ Menerima notifikasi tugas baru
3. ✅ Input hasil pekerjaan dengan foto
4. ✅ Ubah status tugas (pending → in_progress → completed)
5. ✅ Otomatis update activity log setelah tugas selesai

---

## Files yang Dibuat/Dimodifikasi

### 1. File Baru
- **`lib/my_tasks_page.dart`** - Halaman jadwal tugas karyawan lengkap dengan:
  - List view tugas dengan 3 tab (Menunggu, Sedang Dikerjakan, Selesai)
  - Form input hasil kerja
  - Upload foto
  - Status kondisi (Baik, Perlu Perhatian, Ada Kendala)
  - Deskripsi pekerjaan dan catatan

### 2. File Dimodifikasi
- **`lib/main.dart`**
  - Menambahkan route `/my-tasks`
  - Import MyTasksPage

- **`lib/home_page.dart`**
  - Menghubungkan tombol "Jadwal Tugas" ke `/my-tasks`
  - Menghubungkan tombol "Buat Laporan" ke `/my-tasks`

- **`lib/notification_service.dart`**
  - Menambahkan fungsi `_checkNewSchedules()` untuk notifikasi tugas baru
  - Auto-notify untuk tugas hari ini atau besok

---

## Alur Fitur

### A. Melihat Jadwal Tugas

```
1. Karyawan login
2. Di home page, tap tombol "Jadwal Tugas"
3. Halaman My Tasks terbuka dengan 3 tab:
   - Menunggu: Tugas yang belum dimulai
   - Sedang Dikerjakan: Tugas yang sedang diproses
   - Selesai: Tugas yang sudah completed
```

### B. Mulai Tugas (Pending → In Progress)

```
1. Di tab "Menunggu", tap tugas yang ingin dimulai
2. Atau tap tombol "Mulai Tugas" pada card
3. Halaman detail tugas terbuka
4. Karyawan mengisi form dan upload foto
5. Submit → Status berubah jadi "in_progress"
```

### C. Selesaikan Tugas (In Progress → Completed)

```
1. Di tab "Sedang Dikerjakan", tap tugas
2. Atau tap tombol "Selesaikan Tugas"
3. Isi form hasil kerja:
   ✓ Ambil foto hasil kerja (wajib)
   ✓ Pilih status kondisi:
     - Baik
     - Perlu Perhatian
     - Ada Kendala (wajib isi deskripsi kendala)
   ✓ Deskripsi pekerjaan (wajib)
   ✓ Catatan (opsional)
4. Tap "Kirim Laporan"
5. Status berubah jadi "completed"
6. Activity log otomatis terisi
7. Notifikasi muncul
```

---

## UI Components

### 1. Task List Page

**Header:**
- Title: "Jadwal Tugas Saya"
- Refresh button

**Tab Bar:**
- Tab 1: Menunggu (count)
- Tab 2: Sedang Dikerjakan (count)
- Tab 3: Selesai (count)

**Task Card:**
```
┌─────────────────────────────────────────┐
│ [Icon] Checkpoint Name           [Badge]│
│        Area Name                         │
│────────────────────────────────────────│
│ 📅 Senin, 27 Jan    🕐 08:00           │
│                                          │
│ [Tombol Action Sesuai Status]           │
└─────────────────────────────────────────┘
```

**Action Buttons:**
- Status Pending: "Mulai Tugas" (Primary)
- Status In Progress: "Selesaikan Tugas" (Green)
- Status Completed: No button (read-only)

### 2. Task Detail Input Page

**Sections:**

1. **Informasi Tugas** (Read-only card)
   - Checkpoint
   - Area
   - Tanggal
   - Waktu

2. **Foto Hasil Kerja** (Required)
   - Button "Ambil Foto"
   - Preview foto yang diambil
   - Button hapus foto (X)

3. **Status Kondisi** (Required)
   - Choice chips: Baik | Perlu Perhatian | Ada Kendala

4. **Deskripsi Pekerjaan** (Required)
   - Multiline text field (4 lines)

5. **Deskripsi Kendala** (Conditional - jika status "Ada Kendala")
   - Multiline text field (3 lines)

6. **Catatan** (Optional)
   - Multiline text field (2 lines)

7. **Submit Button**
   - "Kirim Laporan" (Green, full width)
   - Loading indicator saat submitting

---

## API Integration

### Endpoints yang Digunakan

1. **GET `/api/schedules`**
   - Mengambil daftar jadwal tugas user yang login
   - Response: Array of schedules dengan status

2. **POST `/api/reports`**
   - Submit laporan hasil kerja
   - Payload:
     - `schedule_id`: ID jadwal
     - `latitude`, `longitude`: GPS location
     - `condition_status`: Baik/Perlu Perhatian/Ada Kendala
     - `work_description`: Deskripsi pekerjaan
     - `notes`: Catatan (optional)
     - `issue_description`: Deskripsi kendala (jika status Ada Kendala)
     - `photo`: File foto (multipart)

### Data Flow

```
Backend Admin Panel
    ↓ (assigns task)
Schedule created with status: pending
    ↓
Karyawan login → GET /api/schedules
    ↓
Tampil di "Menunggu" tab
    ↓
Karyawan mulai & selesaikan tugas
    ↓
POST /api/reports
    ↓
Backend update schedule status: completed
    ↓
Response reportData
    ↓
Frontend update:
  - Activity log
  - Notification
  - Refresh task list
```

---

## Notification System

### Jenis Notifikasi

1. **Tugas Baru Hari Ini**
   - Icon: 📋
   - Title: "Tugas Baru"
   - Body: "Anda memiliki tugas di {checkpoint} hari ini"
   - Triggered: Saat polling detect tugas untuk hari ini

2. **Tugas Besok**
   - Icon: 📋
   - Title: "Tugas Baru"
   - Body: "Anda memiliki tugas di {checkpoint} besok"
   - Triggered: Saat polling detect tugas untuk besok

3. **Reminder 30 Menit Sebelum**
   - Icon: ⏰
   - Title: "Pengingat Tugas"
   - Body: "Tugas di {checkpoint} akan dimulai dalam 30 menit"
   - Triggered: Auto check setiap 2 menit

4. **Tugas Selesai**
   - Icon: 📄
   - Title: "Aktivitas Baru"
   - Body: "Tugas '{checkpoint}' telah diselesaikan"
   - Triggered: Setelah submit laporan

### Notification Polling

- **Interval**: Setiap 2 menit
- **Checks**:
  - New schedules (hari ini/besok)
  - Upcoming schedules (30 min window)
- **Storage**: Persist di SharedPreferences
- **Deduplication**: Menggunakan unique notification ID

---

## Status Badge Colors

| Status | Color | Label |
|--------|-------|-------|
| `pending` | Grey (#AB8985) | Menunggu |
| `in_progress` | Yellow (#FBBF24) | Sedang Dikerjakan |
| `completed` | Green (#4CAF50) | Selesai |

---

## Validations

### Form Validations

1. **Foto** (Required)
   - Error: "Foto harus diambil"
   - Check: `_photoFile != null`

2. **Status Kondisi** (Required)
   - Default: "Baik"
   - Options: Baik, Perlu Perhatian, Ada Kendala

3. **Deskripsi Pekerjaan** (Required)
   - Error: "Deskripsi pekerjaan harus diisi"
   - Min: 1 character (setelah trim)

4. **Deskripsi Kendala** (Conditional Required)
   - Only required if status = "Ada Kendala"
   - Error: "Deskripsi kendala harus diisi"

5. **Catatan** (Optional)
   - No validation

### GPS Validation

- Uses `Geolocator.getCurrentPosition()`
- Accuracy: `LocationAccuracy.high`
- No radius validation (submit anywhere)
- Error handling: Show snackbar if location fails

### Photo Validation

- **Format**: JPG (via ImagePicker)
- **Compression**: 
  - Max width: 1920px
  - Max height: 1080px
  - Quality: 85%
- **Source**: Camera only (not gallery)

---

## Error Handling

### API Errors

```dart
try {
  await apiService.submitReport(...);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString().replaceAll('Exception: ', '')),
      backgroundColor: AppTheme.alertCritical,
    ),
  );
}
```

### Location Errors

- Permission denied → Show error snackbar
- Location services disabled → Show error snackbar
- Timeout → Show error snackbar

### Photo Errors

- Camera not available → Picker will show error
- No photo taken → Validation error before submit

---

## User Experience

### Empty States

**Menunggu Tab (Empty):**
```
      [Icon task_alt]
  Tidak ada tugas menunggu
```

**Sedang Dikerjakan Tab (Empty):**
```
   [Icon pending_actions]
Tidak ada tugas sedang dikerjakan
```

**Selesai Tab (Empty):**
```
   [Icon check_circle_outline]
   Belum ada tugas selesai
```

### Loading States

- **Initial Load**: Center CircularProgressIndicator
- **Submitting**: Button shows loading spinner (20x20)
- **Refreshing**: Pull-to-refresh indicator

### Success States

- **After Submit**: 
  - Green snackbar: "Laporan berhasil dikirim"
  - Auto navigate back
  - Task list auto-refresh
  - Activity log updated
  - Notification added

---

## Testing Checklist

### Functional Testing

- [ ] Login sebagai karyawan
- [ ] Buka halaman Jadwal Tugas dari home
- [ ] Verify tugas muncul di tab yang sesuai
- [ ] Tap tugas untuk buka detail
- [ ] Ambil foto menggunakan camera
- [ ] Pilih status kondisi
- [ ] Isi deskripsi pekerjaan
- [ ] Submit laporan
- [ ] Verify success message
- [ ] Verify tugas pindah ke tab "Selesai"
- [ ] Verify activity log updated
- [ ] Verify notifikasi muncul

### Notification Testing

- [ ] Admin assign tugas untuk hari ini
- [ ] Karyawan login
- [ ] Wait 2 minutes (polling interval)
- [ ] Check notification bell badge
- [ ] Buka notifications page
- [ ] Verify notifikasi "Tugas Baru" muncul

### Edge Cases

- [ ] Submit tanpa foto → Error
- [ ] Submit tanpa deskripsi → Error
- [ ] Pilih "Ada Kendala" tanpa isi deskripsi kendala → Error
- [ ] No GPS signal → Error handling
- [ ] API timeout → Error handling
- [ ] Offline mode → Queue for sync

---

## Future Enhancements

### Potential Improvements

1. **QR Code Scanner**
   - Scan QR di lokasi checkpoint
   - Verifikasi lokasi fisik

2. **Timer Tracking**
   - Start timer saat mulai tugas
   - Stop timer saat selesai
   - Show duration in report

3. **Voice Notes**
   - Record audio catatan
   - Attach to report

4. **Multi-Photo**
   - Upload multiple photos
   - Before & after photos

5. **Offline Support**
   - Queue reports when offline
   - Auto-sync when online
   - Show sync status

6. **Task History**
   - Detailed history per checkpoint
   - Statistics & trends
   - Personal performance metrics

---

## Troubleshooting

### "Tidak ada jadwal tugas"
**Penyebab**: Admin belum assign tugas
**Solusi**: Minta admin untuk assign tugas di backend panel

### "Foto harus diambil" meskipun sudah foto
**Penyebab**: `_photoFile` null
**Solusi**: Debug camera permission atau ImagePicker issue

### "Laporan gagal dikirim"
**Penyebab**: API error atau network issue
**Solusi**: 
1. Check backend running
2. Check network connection
3. Check API logs

### Notifikasi tidak muncul
**Penyebab**: Polling belum berjalan atau belum 2 menit
**Solusi**: Wait 2 minutes atau restart app

---

## Navigation Flow

```
Home Page
    ↓ Tap "Jadwal Tugas"
My Tasks Page (Tab: Menunggu)
    ↓ Tap tugas
Task Detail Input Page
    ↓ Fill form & submit
    ↓ Success
My Tasks Page (Tab: Selesai)
    ↓ Back button
Home Page (dengan updated activity log)
```

---

**Status**: ✅ Complete & Ready for Testing  
**Date**: January 2025  
**Version**: 1.0.0
