import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'image_utils.dart';
import 'main.dart' show ActivityLogProvider, NotificationProvider;

/// Halaman Jadwal Tugas Saya - Karyawan dapat melihat dan menyelesaikan tugas
class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _highlightScheduleId; // For highlighting specific task from notification
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSchedules();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get schedule ID from route arguments (from notification)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('scheduleId')) {
      _highlightScheduleId = args['scheduleId'] as int?;
      
      // After schedules loaded, find and navigate to the right tab
      if (_schedules.isNotEmpty && _highlightScheduleId != null) {
        _navigateToTask(_highlightScheduleId!);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final schedules = await _apiService.getSchedules();
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
      
      // After loading, navigate to highlighted task if specified
      if (_highlightScheduleId != null) {
        _navigateToTask(_highlightScheduleId!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _navigateToTask(int scheduleId) {
    // Find the task and determine which tab it's in
    final task = _schedules.firstWhere(
      (s) => s['id'] == scheduleId,
      orElse: () => null,
    );

    if (task == null) return;

    final status = task['status'] as String?;
    int tabIndex = 0;

    if (status == 'pending') {
      tabIndex = 0;
    } else if (status == 'in_progress') {
      tabIndex = 1;
    } else if (status == 'completed') {
      tabIndex = 2;
    }

    // Switch to the correct tab
    if (_tabController.index != tabIndex) {
      _tabController.animateTo(tabIndex);
    }

    // Auto-open the task detail after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _openTaskDetail(task);
      }
    });
  }

  List<dynamic> get _pendingTasks => _schedules
      .where((s) => s['status'] == 'pending')
      .toList();

  List<dynamic> get _inProgressTasks => _schedules
      .where((s) => s['status'] == 'in_progress')
      .toList();

  List<dynamic> get _completedTasks => _schedules
      .where((s) => s['status'] == 'completed')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Jadwal Tugas Saya', style: AppTheme.titleLg),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
            tooltip: 'Muat ulang',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBrand,
          unselectedLabelColor: AppTheme.outline,
          indicatorColor: AppTheme.primaryBrand,
          tabs: [
            Tab(text: 'Menunggu (${_pendingTasks.length})'),
            Tab(text: 'Sedang Dikerjakan (${_inProgressTasks.length})'),
            Tab(text: 'Selesai (${_completedTasks.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(_pendingTasks, 'pending'),
                    _buildTaskList(_inProgressTasks, 'in_progress'),
                    _buildTaskList(_completedTasks, 'completed'),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.alertCritical),
            const SizedBox(height: AppTheme.spMd),
            Text(_errorMessage, style: AppTheme.bodyLg, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spLg),
            ElevatedButton.icon(
              onPressed: _loadSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks, String status) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending' ? Icons.task_alt : 
              status == 'in_progress' ? Icons.pending_actions :
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spMd),
            Text(
              status == 'pending' ? 'Tidak ada tugas menunggu' :
              status == 'in_progress' ? 'Tidak ada tugas sedang dikerjakan' :
              'Belum ada tugas selesai',
              style: AppTheme.bodyLg,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchedules,
      color: AppTheme.primaryBrand,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spMd),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _TaskCard(
            task: task,
            onTap: () => _openTaskDetail(task),
            onRefresh: _loadSchedules,
          );
        },
      ),
    );
  }

  void _openTaskDetail(Map<String, dynamic> task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailInputPage(
          task: task,
          apiService: _apiService,
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadSchedules();
      }
    });
  }
}

/// Card untuk menampilkan satu tugas
class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final checkpoint = task['checkpoint'] as Map<String, dynamic>? ?? {};
    final area = checkpoint['area'] as Map<String, dynamic>? ?? {};
    final status = task['status'] as String? ?? 'pending';
    final scheduledTime = task['scheduled_time'] as String?;
    final shiftDate = task['shift_date'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spSm),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      size: 20,
                      color: _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checkpoint['name'] ?? 'Checkpoint',
                          style: AppTheme.bodyLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          area['name'] ?? 'Area',
                          style: AppTheme.labelMd.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: AppTheme.spMd),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.spMd),
              
              // Info
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.outline),
                  const SizedBox(width: AppTheme.spSm),
                  Text(
                    _formatDate(shiftDate ?? ''),
                    style: AppTheme.bodyMd,
                  ),
                  const SizedBox(width: AppTheme.spLg),
                  const Icon(Icons.access_time, size: 16, color: AppTheme.outline),
                  const SizedBox(width: AppTheme.spSm),
                  Text(
                    scheduledTime?.substring(0, 5) ?? '-',
                    style: AppTheme.bodyMd,
                  ),
                ],
              ),
              
              if (status == 'pending') ...[
                const SizedBox(height: AppTheme.spMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Mulai Tugas'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spSm),
                    ),
                  ),
                ),
              ],
              
              if (status == 'in_progress') ...[
                const SizedBox(height: AppTheme.spMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Selesaikan Tugas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusOk,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spSm),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'completed' => AppTheme.statusOk,
      'in_progress' => AppTheme.statusWarning,
      _ => AppTheme.outline,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'completed' => Icons.check_circle,
      'in_progress' => Icons.pending,
      _ => Icons.schedule,
    };
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppTheme.statusOk,
      'in_progress' => AppTheme.statusWarning,
      _ => AppTheme.outline,
    };

    final label = switch (status) {
      'completed' => 'Selesai',
      'in_progress' => 'Sedang Dikerjakan',
      _ => 'Menunggu',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spSm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTheme.labelSm.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Halaman Detail untuk Input Hasil Kerja
class TaskDetailInputPage extends StatefulWidget {
  final Map<String, dynamic> task;
  final ApiService apiService;

  const TaskDetailInputPage({
    super.key,
    required this.task,
    required this.apiService,
  });

  @override
  State<TaskDetailInputPage> createState() => _TaskDetailInputPageState();
}

class _TaskDetailInputPageState extends State<TaskDetailInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _workDescController = TextEditingController();
  final _notesController = TextEditingController();
  final _issueDescController = TextEditingController();
  
  String _conditionStatus = 'Baik';
  File? _photoFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _workDescController.dispose();
    _notesController.dispose();
    _issueDescController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto harus diambil')),
      );
      return;
    }

    if (_conditionStatus == 'Ada Kendala' && _issueDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi kendala harus diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Read and compress photo
      final photoFileBytes = await _photoFile!.readAsBytes();
      final photoBytes = await ImageUtils.compressImage(photoFileBytes);
      final photoName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Submit report
      final reportData = await widget.apiService.submitReport(
        scheduleId: widget.task['id'] as int,
        latitude: position.latitude,
        longitude: position.longitude,
        conditionStatus: _conditionStatus,
        workDescription: _workDescController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        issueDescription: _conditionStatus == 'Ada Kendala' ? _issueDescController.text.trim() : null,
        photoBytes: photoBytes,
        photoName: photoName,
      );

      // Trigger notification
      if (mounted) {
        final notificationService = NotificationProvider.of(context);
        notificationService.notifyNewReport(
          'Tugas "${widget.task['checkpoint']['name']}" telah diselesaikan',
        );

        // Update activity log
        ActivityLogProvider.of(context).pushReport(
          reportData: reportData,
          schedule: widget.task,
          userName: 'Anda',
          photoBytes: photoBytes,
          photoLocalPath: _photoFile!.path,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          issueDescription: _conditionStatus == 'Ada Kendala' ? _issueDescController.text.trim() : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirim'),
            backgroundColor: AppTheme.statusOk,
          ),
        );
        Navigator.of(context).pop(true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.alertCritical,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkpoint = widget.task['checkpoint'] as Map<String, dynamic>? ?? {};
    final area = checkpoint['area'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Input Hasil Kerja'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informasi Tugas', style: AppTheme.headlineSm),
                      const SizedBox(height: AppTheme.spMd),
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Checkpoint',
                        value: checkpoint['name'] ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.domain,
                        label: 'Area',
                        value: area['name'] ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Tanggal',
                        value: _formatDate(widget.task['shift_date'] ?? ''),
                      ),
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Waktu',
                        value: widget.task['scheduled_time']?.substring(0, 5) ?? '-',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spLg),

              // Photo Section
              Text('Foto Hasil Kerja *', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              
              if (_photoFile != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: Image.file(
                        _photoFile!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _photoFile = null),
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Ambil Foto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                  ),
                ),
              const SizedBox(height: AppTheme.spLg),

              // Condition Status
              Text('Status Kondisi *', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              Wrap(
                spacing: AppTheme.spSm,
                children: ['Baik', 'Perlu Perhatian', 'Ada Kendala'].map((condition) {
                  final isSelected = _conditionStatus == condition;
                  return ChoiceChip(
                    label: Text(condition),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _conditionStatus = condition);
                      }
                    },
                    selectedColor: AppTheme.primaryBrand.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryBrand : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spLg),

              // Work Description
              Text('Deskripsi Pekerjaan *', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              TextFormField(
                controller: _workDescController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan pekerjaan yang telah dilakukan...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi pekerjaan harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spLg),

              // Issue Description (if condition is "Ada Kendala")
              if (_conditionStatus == 'Ada Kendala') ...[
                Text('Deskripsi Kendala *', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppTheme.spSm),
                TextFormField(
                  controller: _issueDescController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan kendala yang ditemukan...',
                  ),
                ),
                const SizedBox(height: AppTheme.spLg),
              ],

              // Notes (optional)
              Text('Catatan (Opsional)', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan catatan jika diperlukan...',
                ),
              ),
              const SizedBox(height: AppTheme.spXl),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                  backgroundColor: AppTheme.statusOk,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Kirim Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.outline),
          const SizedBox(width: AppTheme.spSm),
          Text('$label: ', style: AppTheme.bodyMd),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
