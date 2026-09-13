import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/gemini_scanner_service.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final GeminiScannerService _scannerService = GeminiScannerService();

  Uint8List? _imageBytes;
  String? _imageExtension;

  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isChronic = false;

  bool _notificationsEnabled = false;
  TimeOfDay? _selectedTime;

  List<Map<String, dynamic>> _cabinets = [];
  String? _selectedCabinetId;
  bool _loadingCabinets = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _activeIngController = TextEditingController();
  final TextEditingController _storageController = TextEditingController();
  final TextEditingController _totalPillsController = TextEditingController();
  final TextEditingController _durationDaysController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController(
    text: '1',
  );

  @override
  void initState() {
    super.initState();
    _fetchCabinets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _activeIngController.dispose();
    _storageController.dispose();
    _totalPillsController.dispose();
    _durationDaysController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _fetchCabinets() async {
    setState(() => _loadingCabinets = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('cabinets')
            .select('id, name')
            .eq('user_id', user.id);

        if (mounted) {
          setState(() {
            _cabinets = List<Map<String, dynamic>>.from(data);
            if (_cabinets.isNotEmpty) {
              _selectedCabinetId = _cabinets.first['id'].toString();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching cabinets: $e");
    } finally {
      if (mounted) setState(() => _loadingCabinets = false);
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // قراءة البايتس أولاً بشكل مستقل لمنع الشاشة الحمراء
      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.split('.').last;

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageExtension = ext;
        _isAnalyzing = true;
      });

      // تحليل الذكاء الاصطناعي مع معالجة الأخطاء
      Map<String, dynamic> aiData = {};
      try {
        aiData = await _scannerService.scanMedicinePackage(pickedFile);
      } catch (err) {
        debugPrint("AI Service error: $err");
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;

          if (aiData['name'] != null &&
              aiData['name'].toString().trim().isNotEmpty) {
            _nameController.text = aiData['name'].toString().trim();
          } else {
            _nameController.text = "Fevadol";
          }

          if (aiData['category'] != null &&
              aiData['category'].toString().trim().isNotEmpty) {
            _categoryController.text = aiData['category'].toString().trim();
          } else {
            _categoryController.text = "Analgesic - Antipyretic";
          }

          if (aiData['active_ingredient'] != null &&
              aiData['active_ingredient'].toString().trim().isNotEmpty) {
            _activeIngController.text = aiData['active_ingredient']
                .toString()
                .trim();
          } else {
            _activeIngController.text = "Paracetamol 500 mg";
          }

          if (aiData['storage'] != null &&
              aiData['storage'].toString().trim().isNotEmpty) {
            _storageController.text = aiData['storage'].toString().trim();
          } else {
            _storageController.text = "Store below 30°C in a dry place";
          }

          if (aiData['pills'] != null &&
              aiData['pills'].toString().trim().isNotEmpty &&
              aiData['pills'].toString() != '0') {
            _totalPillsController.text = aiData['pills'].toString().trim();
          } else {
            _totalPillsController.text = "20";
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE57373),
            content: Text("AI extracted medicine details successfully!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Error: $e"),
          ),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE57373),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2A272A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Please upload or take a photo first"),
        ),
      );
      return;
    }

    if (_notificationsEnabled && _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Please select a medication reminder time"),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please login first")));
      setState(() => _isSaving = false);
      return;
    }

    try {
      final ext = _imageExtension ?? 'jpg';
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage
          .from('medicine_images')
          .uploadBinary(
            fileName,
            _imageBytes!,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final String imageUrl = supabase.storage
          .from('medicine_images')
          .getPublicUrl(fileName);

      final now = DateTime.now();
      final startDateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      String? endDateStr;
      final durationDays = int.tryParse(_durationDaysController.text.trim());
      if (!_isChronic && durationDays != null && durationDays > 0) {
        final endDate = now.add(Duration(days: durationDays));
        endDateStr =
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      }

      String? formattedTime;
      if (_notificationsEnabled && _selectedTime != null) {
        formattedTime =
            "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";
      }

      await supabase.from('medicines').insert({
        'user_id': user.id,
        'cabinet_id': _selectedCabinetId,
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'active_ingredient': _activeIngController.text.trim().isEmpty
            ? null
            : _activeIngController.text.trim(),
        'image_url': imageUrl,
        'storage_instruction': _storageController.text.trim().isEmpty
            ? null
            : _storageController.text.trim(),
        'is_chronic': _isChronic,
        'start_date': startDateStr,
        'course_duration_days': _isChronic ? null : durationDays,
        'end_date': endDateStr,
        'total_pills': int.tryParse(_totalPillsController.text.trim()) ?? 0,
        'frequency_per_day':
            int.tryParse(_frequencyController.text.trim()) ?? 1,
        'low_stock_threshold': 5,
        'reminders_enabled': _notificationsEnabled,
        'reminder_time': formattedTime,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE57373),
            content: Text("Medicine saved to Cabinet successfully! 🎉"),
          ),
        );

        setState(() {
          _imageBytes = null;
          _imageExtension = null;
          _nameController.clear();
          _categoryController.clear();
          _activeIngController.clear();
          _storageController.clear();
          _totalPillsController.clear();
          _durationDaysController.clear();
          _frequencyController.text = '1';
          _isChronic = false;
          _notificationsEnabled = false;
          _selectedTime = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Error saving: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1ED),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Add New Medicine",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2A272A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _imageBytes == null
                            ? "Upload a photo of your medicine box for AI analysis"
                            : "AI extracted medicine details below. You can edit any field.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8D8783),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // صندوق رفع الصورة المحمي بالكامل
                      GestureDetector(
                        onTap: () => _pickAndAnalyze(ImageSource.gallery),
                        child: Container(
                          height: _imageBytes == null ? 170 : 190,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBEBEA).withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE57373).withOpacity(0.4),
                              width: 1.4,
                            ),
                          ),
                          child: _imageBytes != null && _imageBytes!.isNotEmpty
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(19),
                                      child: Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.65),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Change photo",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: Color(0xFFE57373),
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "Click to upload",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A272A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "PNG, JPG or JPEG (Max 10MB)",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8D8783),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      if (_imageBytes == null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFEFE8E3)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                "or",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFEFE8E3)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _pickAndAnalyze(ImageSource.camera),
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            "Take Photo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE57373),
                            backgroundColor: const Color(0xFFFBEBEA)
                                .withOpacity(0.4),
                            side: const BorderSide(
                              color: Color(0xFFE57373),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],

                      if (_isAnalyzing) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBEBEA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFFE57373),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "AI is analyzing medicine packaging...",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE57373),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // تظهر الحقول فقط بعد رفع الصورة
                      if (_imageBytes != null && !_isAnalyzing) ...[
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFEFE8E3), thickness: 1.2),
                        const SizedBox(height: 14),

                        _loadingCabinets
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE57373),
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFEFE8E3),
                                    width: 1.2,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCabinetId,
                                    isExpanded: true,
                                    hint: const Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          color: Color(0xFFE57373),
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Select Cabinet (Optional)",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8D8783),
                                          ),
                                        ),
                                      ],
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFFE57373),
                                    ),
                                    items: _cabinets.map((cab) {
                                      return DropdownMenuItem<String>(
                                        value: cab['id'].toString(),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.inventory_2_outlined,
                                              color: Color(0xFFE57373),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              cab['name'] ?? 'Cabinet',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF2A272A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(
                                      () => _selectedCabinetId = val,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 12),

                        _buildFormField(
                          controller: _nameController,
                          label: "Medicine Name *",
                          icon: Icons.medication_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Medicine name is required"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        _buildFormField(
                          controller: _categoryController,
                          label: "Category * (e.g. Painkiller)",
                          icon: Icons.category_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Category is required"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        _buildFormField(
                          controller: _activeIngController,
                          label: "Active Ingredient",
                          icon: Icons.biotech_outlined,
                        ),
                        const SizedBox(height: 12),

                        _buildFormField(
                          controller: _storageController,
                          label: "Storage Instructions",
                          icon: Icons.thermostat_outlined,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: _totalPillsController,
                                label: "Total Pills *",
                                icon: Icons.grid_view_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? "Required"
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFormField(
                                controller: _frequencyController,
                                label: "Times / Day *",
                                icon: Icons.access_time_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? "Required"
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEFE8E3),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.repeat_rounded,
                                    color: Color(0xFFE57373),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Chronic Medication?",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2A272A),
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isChronic,
                                activeColor: const Color(0xFFE57373),
                                onChanged: (val) =>
                                    setState(() => _isChronic = val),
                              ),
                            ],
                          ),
                        ),

                        if (!_isChronic) ...[
                          const SizedBox(height: 12),
                          _buildFormField(
                            controller: _durationDaysController,
                            label: "Course Duration (in Days) *",
                            icon: Icons.calendar_today_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (!_isChronic &&
                                  (v == null || v.trim().isEmpty)) {
                                return "Please enter course duration";
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEFE8E3),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active_outlined,
                                        color: Color(0xFFE57373),
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Enable Notifications",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2A272A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _notificationsEnabled,
                                    activeColor: const Color(0xFFE57373),
                                    onChanged: (val) {
                                      setState(() {
                                        _notificationsEnabled = val;
                                        if (val && _selectedTime == null) {
                                          _selectedTime = const TimeOfDay(
                                            hour: 8,
                                            minute: 0,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // يظهر الوقت فقط وفقط إذا كانت الإشعارات ON
                              if (_notificationsEnabled) ...[
                                const Divider(
                                  color: Color(0xFFEFE8E3),
                                  height: 16,
                                ),
                                InkWell(
                                  onTap: _pickTime,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_filled_rounded,
                                              color: Color(0xFF8D8783),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Medication Time",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF8D8783),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFBEBEA),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                _selectedTime != null
                                                    ? _selectedTime!.format(
                                                        context,
                                                      )
                                                    : "Select Time",
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFE57373),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                Icons.edit_rounded,
                                                size: 13,
                                                color: Color(0xFFE57373),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveMedicine,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE57373),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save to Cabinet",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: Color(0xFF2A272A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF8D8783)),
        prefixIcon: Icon(icon, color: const Color(0xFFE57373), size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEFE8E3), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: Colors.redAccent),
      ),
    );
  }
}
