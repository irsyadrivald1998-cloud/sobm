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
    const bgDark = Color(0xFF0F0F14);
    const cardBg = Color(0xFF1C1C26);
    const textColor = Color(0xFFF0F0F5);
    const subtextColor = Color(0xFFB0B0C0);
    const borderCol = Color(0xFF3A3A48);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          'Pengajuan Izin/Cuti/Sakit',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF16161E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leave Type Selection
              const Text(
                'Jenis Pengajuan',
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spSm),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTypeChip('cuti', 'Cuti', Icons.beach_access_rounded),
                    _buildTypeChip('izin', 'Izin', Icons.event_note_rounded),
                    _buildTypeChip('sakit', 'Sakit', Icons.local_hospital_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spLg),

              // Start Date
              const Text(
                'Tanggal Mulai',
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryBrand),
                      const SizedBox(width: AppTheme.spSm + 4),
                      Text(
                        _formatDate(_startDate),
                        style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spMd),

              // End Date
              const Text(
                'Tanggal Selesai',
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryBrand),
                      const SizedBox(width: AppTheme.spSm + 4),
                      Text(
                        _formatDate(_endDate),
                        style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spSm),
              Text(
                'Durasi: ${_endDate.difference(_startDate).inDays + 1} hari',
                style: const TextStyle(color: AppTheme.primaryBrand, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spLg),

              // Reason
              const Text(
                'Alasan',
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spSm),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                style: const TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Jelaskan alasan pengajuan $_leaveType...',
                  hintStyle: const TextStyle(color: Color(0xFF7A7A8E), fontSize: 14),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderCol),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderCol),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryBrand, width: 1.5),
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
                style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spSm),
              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: Icon(
                  _attachmentFile == null ? Icons.attach_file_rounded : Icons.check_circle_rounded,
                  color: _attachmentFile == null ? subtextColor : AppTheme.statusOk,
                ),
                label: Text(
                  _attachmentFile == null
                      ? 'Pilih Surat ${_leaveType == 'sakit' ? 'Dokter' : 'Izin'}'
                      : 'File terlampir: ${_attachmentFile!.name}',
                  style: TextStyle(
                    color: _attachmentFile == null ? subtextColor : AppTheme.statusOk,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: BorderSide(
                    color: _attachmentFile == null ? borderCol : AppTheme.statusOk,
                  ),
                  backgroundColor: cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (_leaveType != 'cuti')
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spXs + 2),
                  child: Text(
                    _leaveType == 'sakit'
                        ? 'Wajib melampirkan surat keterangan dokter'
                        : 'Wajib melampirkan surat izin resmi',
                    style: const TextStyle(
                      color: AppTheme.statusWarning,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.spXl),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Kirim Pengajuan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _leaveType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _leaveType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBrand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFFB0B0C0)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFB0B0C0),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
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
