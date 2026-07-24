# Deep Linking dari Notifikasi ke Tugas

## Overview
Fitur ini memungkinkan notifikasi untuk **langsung membuka tugas spesifik** ketika di-tap oleh karyawan.

---

## Cara Kerja

### 1. Notifikasi Dibuat dengan Schedule ID

Saat notifikasi dibuat (misal: tugas baru), schedule ID disimpan dalam `data`:

```dart
AppNotification(
  id: 'schedule_new_123',
  type: NotificationType.schedule,
  title: '📋 Tugas Baru',
  body: 'Anda memiliki tugas di Checkpoint A hari ini',
  timestamp: DateTime.now(),
  data: {'schedule_id': 123}, // ← ID tugas disimpan di sini
)
```

### 2. User Tap Notifikasi

Ketika user tap notifikasi di `notifications_page.dart`:

```dart
void _handleNotificationTap(BuildContext context, AppNotification notification) {
  final scheduleId = notification.data?['schedule_id'] as int?;
  
  // Navigate dengan arguments
  Navigator.of(context).pushNamed(
    '/my-tasks',
    arguments: {'scheduleId': scheduleId},
  );
}
```

### 3. MyTasksPage Menerima Arguments

Di `my_tasks_page.dart`, page menerima schedule ID:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  if (args != null && args.containsKey('scheduleId')) {
    _highlightScheduleId = args['scheduleId'] as int?;
  }
}
```

### 4. Auto-Navigate ke Tugas

Setelah schedules loaded, page otomatis:
1. **Cari tugas** dengan ID yang sesuai
2. **Switch tab** sesuai status tugas:
   - `pending` → Tab 0 (Menunggu)
   - `in_progress` → Tab 1 (Sedang Dikerjakan)
   - `completed` → Tab 2 (Selesai)
3. **Buka detail tugas** otomatis

```dart
void _navigateToTask(int scheduleId) {
  final task = _schedules.firstWhere((s) => s['id'] == scheduleId);
  
  // Determine tab
  final status = task['status'];
  int tabIndex = status == 'pending' ? 0 : 
                 status == 'in_progress' ? 1 : 2;
  
  // Switch tab
  _tabController.animateTo(tabIndex);
  
  // Open task detail
  Future.delayed(Duration(milliseconds: 300), () {
    _openTaskDetail(task);
  });
}
```

---

## Navigation Flow

```
User receives notification
    ↓ (notification bell shows badge)
User taps bell icon
    ↓
Opens Notifications Page
    ↓
User taps specific notification
    ↓
_handleNotificationTap() called
    ↓
Extract scheduleId from notification.data
    ↓
Navigator.pushNamed('/my-tasks', arguments: {scheduleId})
    ↓
MyTasksPage opens
    ↓
didChangeDependencies() extracts scheduleId
    ↓
After schedules loaded → _navigateToTask()
    ↓
Find task by ID
    ↓
Switch to correct tab (Menunggu/Sedang Dikerjakan/Selesai)
    ↓
Auto-open task detail page
    ↓
User can fill form and submit
```

---

## Notification Type Routing

| Notification Type | Action When Tapped |
|-------------------|-------------------|
| **schedule** | Navigate to `/my-tasks` with scheduleId → Auto-open task |
| **reminder** | Navigate to `/my-tasks` with scheduleId → Auto-open task |
| **issue** | Navigate to `/activity-log` |
| **report** | Navigate to `/activity-log` |
| **system** | No navigation (just mark as read) |

---

## Code Changes

### 1. `notifications_page.dart`

**Added:**
- `_handleNotificationTap()` method untuk handle tap notifikasi
- Logic untuk pass scheduleId via route arguments

**Modified:**
- `InkWell.onTap` sekarang call `_handleNotificationTap()` after marking as read

### 2. `my_tasks_page.dart`

**Added:**
- `_highlightScheduleId` state variable
- `didChangeDependencies()` untuk extract route arguments
- `_navigateToTask()` method untuk auto-navigate ke tugas spesifik

**Modified:**
- `_loadSchedules()` sekarang trigger `_navigateToTask()` setelah load

### 3. `notification_service.dart`

**Already Implemented:**
- Notifications sudah include `schedule_id` dalam `data` field
- Format: `data: {'schedule_id': 123}`

---

## User Experience

### Scenario 1: Tugas Baru (Pending)

```
1. Admin assign tugas untuk hari ini
2. Karyawan buka app → Notification badge shows "1"
3. Tap bell icon → Lihat "📋 Tugas Baru"
4. Tap notification
5. App otomatis:
   - Buka halaman My Tasks
   - Switch ke tab "Menunggu"
   - Buka detail tugas tersebut
6. Karyawan langsung bisa isi form
```

### Scenario 2: Reminder 30 Menit Sebelum

```
1. System detect tugas 30 menit lagi
2. Notification: "⏰ Pengingat Tugas"
3. User tap notification
4. App otomatis:
   - Buka My Tasks
   - Tab "Menunggu" (karena masih pending)
   - Buka detail tugas
5. User bisa langsung mulai tugas
```

### Scenario 3: Notifikasi Lama (Task Already Completed)

```
1. User tap old notification
2. App find task by ID
3. Task status = "completed"
4. App:
   - Switch ke tab "Selesai"
   - Buka detail (read-only)
5. User see completed task details
```

---

## Edge Cases Handled

### Task Not Found
```dart
final task = _schedules.firstWhere(
  (s) => s['id'] == scheduleId,
  orElse: () => null,
);

if (task == null) return; // Safe exit
```

### Schedules Not Loaded Yet
```dart
// In _loadSchedules():
if (_highlightScheduleId != null) {
  _navigateToTask(_highlightScheduleId!); // Auto-call after load
}
```

### User Navigates Away Before Auto-Open
```dart
Future.delayed(Duration(milliseconds: 300), () {
  if (mounted) { // ← Check if widget still mounted
    _openTaskDetail(task);
  }
});
```

---

## Testing

### Manual Test Steps

1. **Setup:**
   - Login sebagai karyawan
   - Pastikan ada tugas dengan status "pending"

2. **Trigger Notification:**
   - Wait 2 minutes (untuk polling)
   - Atau restart app (notifications auto-load)

3. **Test Deep Link:**
   - Tap notification bell (badge should show count)
   - Tap specific schedule notification
   - **Verify:**
     - ✅ Navigates to My Tasks page
     - ✅ Correct tab is selected
     - ✅ Task detail opens automatically
     - ✅ Can fill form and submit

4. **Test Different Statuses:**
   - **Pending task:** Should open in "Menunggu" tab
   - **In-progress task:** Should open in "Sedang Dikerjakan" tab
   - **Completed task:** Should open in "Selesai" tab

### Automated Test Cases

```dart
// Test notification tap routing
testWidgets('Notification tap navigates to task', (tester) async {
  final notification = AppNotification(
    id: 'test',
    type: NotificationType.schedule,
    title: 'Test',
    body: 'Test',
    timestamp: DateTime.now(),
    data: {'schedule_id': 123},
  );
  
  // Tap notification
  await tester.tap(find.byType(NotificationTile));
  await tester.pumpAndSettle();
  
  // Verify navigation
  expect(find.byType(MyTasksPage), findsOneWidget);
});
```

---

## Future Enhancements

### 1. Direct Edit from Notification
```dart
// Instead of just opening task list, directly open edit form
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TaskDetailInputPage(
      task: task,
      apiService: apiService,
    ),
  ),
);
```

### 2. Push Notification Support
- Integrate with Firebase Cloud Messaging
- Handle background notification taps
- Deep link works even when app is closed

### 3. Rich Notification Actions
```dart
// Android notification actions
actions: [
  NotificationAction(
    id: 'start',
    title: 'Mulai Tugas',
  ),
  NotificationAction(
    id: 'view',
    title: 'Lihat Detail',
  ),
]
```

### 4. Notification History
- Track which notifications were tapped
- Analytics: which notifications drive most engagement
- Auto-dismiss after task completed

---

## Troubleshooting

### "Task tidak terbuka otomatis"
**Penyebab**: scheduleId tidak ada di notification data
**Solusi**: Verify notification creation includes `data: {'schedule_id': ...}`

### "Tab tidak switch"
**Penyebab**: Status tidak match dengan tab logic
**Solusi**: Check status value in task data

### "App crashes saat tap notification"
**Penyebab**: Task dengan ID tersebut tidak ditemukan
**Solusi**: Already handled with `orElse: () => null` and null check

---

## Summary

✅ **Implemented:**
- Deep linking dari notification ke specific task
- Auto-switch tab berdasarkan status tugas
- Auto-open task detail page
- Safe error handling untuk edge cases

✅ **User Benefits:**
- Faster task access (1 tap dari notification)
- No manual searching untuk tugas
- Better notification UX
- Clear action path: Notification → Task → Complete

✅ **Technical Benefits:**
- Type-safe navigation with arguments
- Proper state management
- Widget lifecycle awareness (mounted check)
- Extensible for future enhancements

---

**Status**: ✅ Complete & Tested  
**Date**: January 2025
