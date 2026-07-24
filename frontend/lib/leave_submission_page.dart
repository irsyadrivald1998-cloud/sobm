import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'api_service.dart';

class LeaveSubmissionPage extends StatefulWidget {
  const LeaveSubmissionPage({super.key});

  @override
  State<LeaveSubmissionPage> createState() => _LeaveSubmissionPageState();
}

class _LeaveSubmissionPageState extends State<LeaveSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final TextEditingController _reasonController = TextEditingController();
  
  String _leaveType = 'cuti';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  XFile? _attachmentFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (file != null) {
        setState(() => _attachmentFile = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_attachmentFile == null && _leaveType != 'cuti') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lampirkan surat izin/sakit'),
          backgroundColor: AppTheme.statusWarning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Uint8List? attachmentBytes;
      if (_attachmentFile != null) {
        attachmentBytes = await _attachmentFile!.readAsBytes();
      }

      await _apiService.submitLeaveRequest(
        leaveType: _leaveType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        attachmentBytes: attachmentBytes,
        attachmentName: _attachmentFile?.name ?? 'attachment.jpg',
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Pengajuan berhasil dikirim'),
                ),
              ],
            ),
            backgroundColor: AppTheme.statusOk,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Pengajuan Izin/Cuti/Sakit', style: AppTheme.titleLg),
        backgroundColor: AppTheme.surfaceLowest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leave Type Selection
              Text('Jenis Pengajuan', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cuti', label: Text('Cuti'), icon: Icon(Icons.beach_access)),
                  ButtonSegment(value: 'izin', label: Text('Izin'), icon: Icon(Icons.event_note)),
                  ButtonSegment(value: 'sakit', label: Text('Sakit'), icon: Icon(Icons.local_hospital)),
                ],
                selected: {_leaveType},
                onSelectionChanged: (Set<String> selection) {
                  setState(() => _leaveType = selection.first);
                },
              ),
              const SizedBox(height: AppTheme.spLg),

              // Start Date
              Text('Tanggal Mulai', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 1));
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spMd),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: AppTheme.spSm),
                      Text(_formatDate(_startDate), style: AppTheme.bodyMd),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spMd),

              // End Date
              Text('Tanggal Selesai', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spMd),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: AppTheme.spSm),
                      Text(_formatDate(_endDate), style: AppTheme.bodyMd),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spSm),
              Text(
                'Durasi: ${_endDate.difference(_startDate).inDays + 1} hari',
                style: AppTheme.labelMd.copyWith(color: AppTheme.primaryBrand),
              ),
              const SizedBox(height: AppTheme.spLg),

              // Reason
              Text('Alasan', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spSm),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Jelaskan alasan pengajuan $_leaveType...',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.outlineVariant),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan harus diisi';
                  }
                  if (value.trim().length < 10) {
                    return 'Alasan terlalu singkat (minimal 10 karakter)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spLg),

              // Attachment
              Text(
                'Lampiran ${_leaveType == 'cuti' ? '(Opsional)' : '(Wajib)'}',
                style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spSm),
              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: Icon(_attachmentFile == null ? Icons.attach_file : Icons.check_circle),
                label: Text(_attachmentFile == null 
                    ? 'Pilih Surat ${_leaveType == 'sakit' ? 'Dokter' : 'Izin'}'
                    : 'File terlampir: ${_attachmentFile!.name}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(AppTheme.spMd),
                  side: BorderSide(
                    color: _attachmentFile == null 
                        ? AppTheme.outlineVariant 
                        : AppTheme.statusOk,
                  ),
                ),
              ),
              if (_leaveType != 'cuti')
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spXs),
                  child: Text(
                    _leaveType == 'sakit' 
                        ? 'Wajib melampirkan surat keterangan dokter'
                        : 'Wajib melampirkan surat izin resmi',
                    style: AppTheme.labelSm.copyWith(
                      color: AppTheme.statusWarning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.spXl),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                  disabledBackgroundColor: AppTheme.outline,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Kirim Pengajuan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
