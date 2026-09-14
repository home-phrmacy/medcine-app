import 'dart:typed_data';
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

  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
  bool _isAnalyzed = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _activeIngredientController = TextEditingController();
  final TextEditingController _storageController = TextEditingController();
  final TextEditingController _totalPillsController = TextEditingController();

  // خانة يدخل فيها المستخدم مدة الكورس بنفسه
  final TextEditingController _courseDurationController = TextEditingController();

  String? _selectedCabinetId;
  List<Map<String, dynamic>> _userCabinets = [];
  bool _isLoadingCabinets = true;

  // هل الدواء مزمن؟
  bool _isChronic = false;

  // تفعيل التنبيهات
  bool _enableNotifications = false;

  int _dosesPerDay = 1;

  final List<TextEditingController> _timeControllers = [
    TextEditingController(text: '08:00'),
  ];
  final List<String> _selectedPeriods = ['AM'];

  @override
  void initState() {
    super.initState();
    _fetchUserCabinets();
  }

  Future<void> _fetchUserCabinets() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final List<dynamic> response = await client
            .from('cabinets')
            .select('id, name')
            .eq('user_id', user.id);

        if (mounted) {
          setState(() {
            _userCabinets = List<Map<String, dynamic>>.from(response);
            _isLoadingCabinets = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingCabinets = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userCabinets = [];
          _isLoadingCabinets = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _activeIngredientController.dispose();
    _storageController.dispose();
    _totalPillsController.dispose();
    _courseDurationController.dispose();
    for (var c in _timeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _isAnalyzing = true;
      });

      final scanner = GeminiScannerService();
      final Map<String, dynamic> result = await scanner.scanMedicinePackage(file);

      setState(() {
        _nameController.text = result['name']?.toString() ?? '';
        _categoryController.text = result['category']?.toString() ?? '';
        _activeIngredientController.text = result['active_ingredient']?.toString() ?? '';
        _storageController.text = result['storage']?.toString() ?? '';
        _totalPillsController.text = (result['pills'] ?? '20').toString();

        _isAnalyzing = false;
        _isAnalyzed = true;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _updateDoseCount(int count) {
    setState(() {
      _dosesPerDay = count;
      while (_timeControllers.length < count) {
        _timeControllers.add(TextEditingController(text: '08:00'));
        _selectedPeriods.add('PM');
      }
      while (_timeControllers.length > count) {
        _timeControllers.removeLast().dispose();
        _selectedPeriods.removeLast();
      }
    });
  }

  Widget _buildTimePickerRow(int index) {
    final bool isAm = _selectedPeriods[index] == 'AM';
    final bool isPm = _selectedPeriods[index] == 'PM';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _timeControllers[index],
                keyboardType: TextInputType.datetime,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
                decoration: InputDecoration(
                  hintText: '08:00',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: Color(0xFFE57373),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedPeriods[index] = 'AM'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAm ? const Color(0xFFE57373) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'AM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAm ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _selectedPeriods[index] = 'PM'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPm ? const Color(0xFFE57373) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'PM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPm ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFFE57373), size: 20),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      List<String> formattedTimes = [];
      if (_enableNotifications) {
        for (int i = 0; i < _dosesPerDay; i++) {
          formattedTimes.add("${_timeControllers[i].text.trim()} ${_selectedPeriods[i]}");
        }
      }

      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('medicines').insert({
            'user_id': user.id,
            'cabinet_id': _selectedCabinetId,
            'name': _nameController.text.trim(),
            'category': _categoryController.text.trim(),
            'active_ingredient': _activeIngredientController.text.trim(),
            'storage': _storageController.text.trim(),
            'total_pills': int.tryParse(_totalPillsController.text) ?? 0,
            'is_chronic': _isChronic,
            'course_days': _isChronic ? null : int.tryParse(_courseDurationController.text),
            'enable_notifications': _enableNotifications,
            'doses_per_day': _enableNotifications ? _dosesPerDay : 1,
            'dose_times': formattedTimes,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicine saved successfully!'),
              backgroundColor: Color(0xFFE57373),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: _isAnalyzed
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Medicine Details',
                style: TextStyle(
                  color: Color(0xFF2D3142),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 18),
                onPressed: () {
                  setState(() {
                    _isAnalyzed = false;
                    _selectedImageBytes = null;
                  });
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // بطاقة رفع الصورة
                  if (!_isAnalyzed)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Add New Medicine',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload a photo of your medicine box for AI analysis',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          InkWell(
                            onTap: () => _pickAndAnalyzeImage(ImageSource.gallery),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF0ED),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF6C5BF),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE57373),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_upload_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Click to upload',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PNG, JPG or JPEG (Max 10MB)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: Color(0xFFE57373),
                              ),
                              label: const Text(
                                'Take Photo',
                                style: TextStyle(
                                  color: Color(0xFFE57373),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE57373), width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // لودينق التحليل
                  if (_isAnalyzing)
                    Padding(
                      padding: const EdgeInsets.only(top: 28.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: Color(0xFFE57373)),
                          const SizedBox(height: 14),
                          Text(
                            'Analyzing medicine package with AI...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // تفاصيل الدواء بعد اكتمال التحليل
                  if (_isAnalyzed && !_isAnalyzing) ...[
                    if (_selectedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: 130,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                    // اختيار الخزانة
                    if (_isLoadingCabinets)
                      const Center(child: CircularProgressIndicator(color: Color(0xFFE57373)))
                    else if (_userCabinets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No cabinets found. Please create a cabinet first from the Cabinet tab.',
                                style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedCabinetId,
                        decoration: InputDecoration(
                          labelText: 'Select Cabinet',
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFFE57373), size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        items: _userCabinets.map((cab) {
                          return DropdownMenuItem<String>(
                            value: cab['id']?.toString() ?? '',
                            child: Text(cab['name']?.toString() ?? 'Unnamed Cabinet'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCabinetId = val),
                      ),

                    const SizedBox(height: 14),

                    _buildReadOnlyField(
                      controller: _nameController,
                      label: 'Medicine Name',
                      icon: Icons.medication_outlined,
                    ),
                    _buildReadOnlyField(
                      controller: _categoryController,
                      label: 'Category',
                      icon: Icons.category_outlined,
                    ),
                    _buildReadOnlyField(
                      controller: _activeIngredientController,
                      label: 'Active Ingredient',
                      icon: Icons.science_outlined,
                    ),
                    _buildReadOnlyField(
                      controller: _storageController,
                      label: 'Storage Instructions',
                      icon: Icons.thermostat_outlined,
                    ),
                    _buildReadOnlyField(
                      controller: _totalPillsController,
                      label: 'Total Quantity / Pills',
                      icon: Icons.numbers_outlined,
                    ),

                    const SizedBox(height: 10),

                    // خيار مزمن أم مؤقت
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.repeat_rounded, color: Colors.blueGrey.shade600, size: 22),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chronic Medicine',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                  ),
                                  Text(
                                    _isChronic ? 'Continuous treatment' : 'Temporary treatment',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isChronic,
                            activeColor: const Color(0xFFE57373),
                            onChanged: (val) => setState(() => _isChronic = val),
                          ),
                        ],
                      ),
                    ),

                    // إذا لم يكن مزمناً: تظهر خانة للمستخدم ليكتب مدة الكورس بالأيام
                    if (!_isChronic) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _courseDurationController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                        decoration: InputDecoration(
                          labelText: 'Course Duration (in days) *',
                          hintText: 'e.g. 7 or 10',
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFFE57373), size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // خيار تفعيل التنبيهات
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _enableNotifications ? const Color(0xFFE57373) : Colors.grey.shade200,
                          width: _enableNotifications ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                color: _enableNotifications ? const Color(0xFFE57373) : Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Remind me to take it',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                  ),
                                  Text(
                                    'Enable dose reminder notifications',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _enableNotifications,
                            activeColor: const Color(0xFFE57373),
                            onChanged: (val) => setState(() => _enableNotifications = val),
                          ),
                        ],
                      ),
                    ),

                    // أوقات الجرعات والـ AM/PM عند تفعيل التنبيهات
                    if (_enableNotifications) ...[
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Doses per day:',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                          ),
                          Row(
                            children: [1, 2].map((count) {
                              final bool isSelected = _dosesPerDay == count;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: InkWell(
                                  onTap: () => _updateDoseCount(count),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFE57373) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFE57373) : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      '$count x',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dose Timings:',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...List.generate(_dosesPerDay, (index) => _buildTimePickerRow(index)),
                    ],

                    const SizedBox(height: 24),

                    // زر الحفظ
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveMedicine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE57373),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Save to Cabinet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}