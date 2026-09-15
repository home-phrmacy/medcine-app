import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phrm_app/screens/add_screen.dart';

class CabinetScreen extends StatefulWidget {
  final String? initialCabinetId;
  final String? initialCabinetName;

  const CabinetScreen({
    super.key,
    this.initialCabinetId,
    this.initialCabinetName,
  });

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  List<Map<String, dynamic>> userCabinets = [];
  List<Map<String, dynamic>> allMedicines = [];

  String? selectedCabinetId;
  String selectedCabinetName = "All Cabinets";
  bool isDropdownOpen = false;
  bool isLoading = true;
  String searchQuery = "";
  String? selectedMedicineId; // لتحديد دواء وظهور أزرار التعديل والحذف له فقط

  @override
  void initState() {
    super.initState();
    selectedCabinetId = widget.initialCabinetId;
    selectedCabinetName = widget.initialCabinetName ?? "All Cabinets";
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    try {
      // 1. جلب الخزانات الفعلية
      var cabQuery = client.from('cabinets').select('id, name');
      if (user != null) {
        cabQuery = cabQuery.or('user_id.eq.${user.id},user_id.is.null');
      }
      final cabData = await cabQuery.order('created_at', ascending: true);

      // 2. جلب جميع الأدوية
      var medQuery = client.from('medicines').select('*');
      if (user != null) {
        medQuery = medQuery.or('user_id.eq.${user.id},user_id.is.null');
      }
      final medData = await medQuery.order('created_at', ascending: false);

      final List<Map<String, dynamic>> meds =
          List<Map<String, dynamic>>.from(medData as List);

      final List<Map<String, dynamic>> loadedCabs = [];
      final Set<String> seenCabIds = {};

      for (var c in (cabData as List)) {
        final cId = c['id'].toString();
        if (seenCabIds.contains(cId)) continue;
        seenCabIds.add(cId);

        final count = meds.where((m) {
          final mCab = m['cabinet_id']?.toString();
          if (mCab == cId) return true;
          if (mCab == null && cabData.length == 1) return true;
          return false;
        }).length;

        loadedCabs.add({
          'id': cId,
          'name': c['name'] ?? 'Cabinet',
          'count': count,
        });
      }

      if (selectedCabinetId != null &&
          !loadedCabs.any((c) => c['id'] == selectedCabinetId)) {
        selectedCabinetId = null;
        selectedCabinetName = "All Cabinets";
      }

      if (mounted) {
        setState(() {
          userCabinets = loadedCabs;
          allMedicines = meds;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _currentMedicines {
    if (selectedCabinetId == null) return [];

    final list = allMedicines.where((m) {
      final mCab = m['cabinet_id']?.toString();
      if (mCab == selectedCabinetId) return true;
      if (mCab == null && userCabinets.length == 1) return true;
      return false;
    }).toList();

    if (searchQuery.trim().isEmpty) return list;
    return list.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredCabinets {
    if (searchQuery.trim().isEmpty) return userCabinets;
    return userCabinets.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  // إضافة خزانة جديدة
  void _addNewCabinet() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "New Cabinet",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Cabinet Name (e.g. My Vitamins)",
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF8D8783))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                final client = Supabase.instance.client;
                final user = client.auth.currentUser;
                await client.from('cabinets').insert({
                  'name': name,
                  'user_id': user?.id,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // تعديل اسم خزانة
  void _renameCabinet(String cabId, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rename Cabinet", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF8D8783))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await Supabase.instance.client
                    .from('cabinets')
                    .update({'name': ctrl.text.trim()})
                    .eq('id', cabId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (selectedCabinetId == cabId) {
                  setState(() => selectedCabinetName = ctrl.text.trim());
                }
                _loadData();
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // حذف خزانة
  Future<void> _deleteCabinet(String cabId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Cabinet"),
        content: const Text("Are you sure you want to delete this cabinet?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final client = Supabase.instance.client;
      await client.from('medicines').update({'cabinet_id': null}).eq('cabinet_id', cabId);
      await client.from('cabinets').delete().eq('id', cabId);
      setState(() {
        selectedCabinetId = null;
        selectedCabinetName = "All Cabinets";
      });
      _loadData();
    }
  }

  // تعديل اسم الدواء
  void _editMedicine(Map<String, dynamic> med) {
    final nameCtrl = TextEditingController(text: med['name'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Medicine Name", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: "Medicine Name",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await Supabase.instance.client
                    .from('medicines')
                    .update({'name': nameCtrl.text.trim()})
                    .eq('id', med['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // حذف دواء
  Future<void> _deleteMedicine(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Medicine"),
        content: const Text("Are you sure you want to delete this medication?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('medicines').delete().eq('id', id);
      setState(() => selectedMedicineId = null);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInsideCabinet = selectedCabinetId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1ED),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس الصفحة مع زر إضافة خزانة جديدة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isInsideCabinet)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF2D3142)),
                              onPressed: () {
                                setState(() {
                                  selectedCabinetId = null;
                                  selectedCabinetName = "All Cabinets";
                                  selectedMedicineId = null;
                                  searchQuery = "";
                                });
                              },
                            ),
                          if (isInsideCabinet) const SizedBox(width: 8),
                          Text(
                            isInsideCabinet ? selectedCabinetName : "Medicine Cabinet",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ],
                      ),
                      // زر إنشاء خزانة جديدة في الأعلى
                      IconButton(
                        onPressed: _addNewCabinet,
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE57373).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.create_new_folder_outlined, color: Color(0xFFE57373), size: 22),
                        ),
                        tooltip: "Add New Cabinet",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // زر الدروب داون الأنيق
                  GestureDetector(
                    onTap: () => setState(() => isDropdownOpen = !isDropdownOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black.withOpacity(0.04)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isInsideCabinet ? Icons.folder_open_rounded : Icons.all_inbox_rounded,
                            color: const Color(0xFFE57373),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedCabinetName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isDropdownOpen ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8D8783)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // البحث
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFBF9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search_rounded, color: Color(0xFFBDBDBD), size: 22),
                        border: InputBorder.none,
                        hintText: isInsideCabinet ? "Search medications..." : "Search cabinets...",
                        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // المحتوى
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE57373)))
                        : isInsideCabinet
                            ? _buildCabinetMedicinesView()
                            : _buildAllCabinetsView(),
                  ),
                ],
              ),
            ),

            // الدروب داون العصري
            if (isDropdownOpen) _buildDropdownOverlay(),
          ],
        ),
      ),
    );
  }

  // 1. عرض الكباين فقط
  Widget _buildAllCabinetsView() {
    final cabs = _filteredCabinets;

    if (cabs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_outlined, size: 55, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 12),
            const Text("No cabinets found", style: TextStyle(color: Color(0xFF8D8783), fontSize: 14)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _addNewCabinet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Create Cabinet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: cabs.length,
      itemBuilder: (ctx, i) {
        final cab = cabs[i];
        final cabId = cab['id'].toString();
        final cabName = cab['name'] ?? 'Cabinet';
        final count = cab['count'] ?? 0;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCabinetId = cabId;
              selectedCabinetName = cabName;
              selectedMedicineId = null;
              searchQuery = "";
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF9),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE57373).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.folder_outlined, color: Color(0xFFE57373), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cabName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$count medicines",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8D8783)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFBDBDBD)),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. عرض أدوية الكابينة المختارة
  Widget _buildCabinetMedicinesView() {
    final meds = _currentMedicines;

    if (meds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE57373).withOpacity(0.12),
              ),
              child: const Icon(Icons.medication_liquid_rounded, size: 42, color: Color(0xFFE57373)),
            ),
            const SizedBox(height: 14),
            Text(
              "No medicines in $selectedCabinetName",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddScreen()))
                    .then((_) => _loadData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("+ Add Medicine"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: meds.length,
      itemBuilder: (ctx, i) => _buildMedicineCard(meds[i]),
    );
  }

  // كرت الدواء: النقر عليه يحدد ويظهر القلم والديليت فقط للدواء المحدد
  Widget _buildMedicineCard(Map<String, dynamic> med) {
    final medId = med['id'].toString();
    final isSelected = selectedMedicineId == medId;

    final name = med['name'] ?? 'Medicine';
    final imageUrl = med['image_url']?.toString();
    final isChronic = med['is_chronic'] == true;

    String durationSubtitle = "Chronic treatment";
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime? calculatedEnd;
    final endDateStr = med['end_date']?.toString() ?? med['course_end_date']?.toString();
    if (endDateStr != null && endDateStr.isNotEmpty) {
      calculatedEnd = DateTime.tryParse(endDateStr);
    } else if (med['course_days'] != null && med['start_date'] != null) {
      final start = DateTime.tryParse(med['start_date'].toString());
      if (start != null) {
        calculatedEnd = start.add(
          Duration(days: int.tryParse(med['course_days'].toString()) ?? 0),
        );
      }
    }

    if (!isChronic && calculatedEnd != null) {
      final daysLeft = calculatedEnd.difference(today).inDays;
      final formattedEnd =
          "${calculatedEnd.year}-${calculatedEnd.month.toString().padLeft(2, '0')}-${calculatedEnd.day.toString().padLeft(2, '0')}";
      if (daysLeft > 0) {
        durationSubtitle = "$daysLeft days left • Ends: $formattedEnd";
      } else if (daysLeft == 0) {
        durationSubtitle = "Ends today • $formattedEnd";
      } else {
        durationSubtitle = "Course completed • Ended: $formattedEnd";
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMedicineId = isSelected ? null : medId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBF9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFE57373) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.06 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // صورة الدواء المرفوعة الحقيقية
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE57373).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medication_outlined,
                        color: Color(0xFFE57373),
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.medication_outlined,
                      color: Color(0xFFE57373),
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),

            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    durationSubtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8D8783)),
                  ),
                ],
              ),
            ),

            // لا تظهر أيقونات التعديل والحذف إلا عند تحديد هذا الدواء فقط!
            if (isSelected) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF8D8783)),
                onPressed: () => _editMedicine(med),
                tooltip: "Edit",
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFE57373)),
                onPressed: () => _deleteMedicine(medId),
                tooltip: "Delete",
              ),
            ],
          ],
        ),
      ),
    );
  }

  // الدروب داون العصري مع علامات التعديل والحذف للخزانة
  Widget _buildDropdownOverlay() {
    return Positioned(
      top: 130,
      left: 20,
      right: 20,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(22),
        shadowColor: Colors.black.withOpacity(0.15),
        color: const Color(0xFFFDFBF9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Cabinets",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8D8783)),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => isDropdownOpen = false);
                      _addNewCabinet();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        "+ Add Cabinet",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE57373),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // خيار All Cabinets
              InkWell(
                onTap: () {
                  setState(() {
                    selectedCabinetId = null;
                    selectedCabinetName = "All Cabinets";
                    selectedMedicineId = null;
                    isDropdownOpen = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: selectedCabinetId == null ? const Color(0xFFE57373).withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.all_inbox_rounded, size: 20, color: Color(0xFFE57373)),
                      const SizedBox(width: 10),
                      Text(
                        "All Cabinets",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedCabinetId == null ? FontWeight.bold : FontWeight.normal,
                          color: selectedCabinetId == null ? const Color(0xFFE57373) : const Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 16),

              // قائمة الكباين الفعلية ومعها أزرار التعديل والحذف
              ...userCabinets.map((cab) {
                final cabId = cab['id'].toString();
                final cabName = cab['name'] ?? 'Cabinet';
                final isSelected = selectedCabinetId == cabId;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE57373).withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedCabinetId = cabId;
                              selectedCabinetName = cabName;
                              selectedMedicineId = null;
                              isDropdownOpen = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 20,
                                  color: isSelected ? const Color(0xFFE57373) : const Color(0xFF6E6A68),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "$cabName (${cab['count']})",
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFFE57373) : const Color(0xFF2D3142),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // أيقونة تعديل الكابينة تظهر هنا داخل الدروب داون
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8D8783)),
                        onPressed: () => _renameCabinet(cabId, cabName),
                        tooltip: "Rename",
                      ),

                      // أيقونة حذف الكابينة تظهر هنا داخل الدروب داون
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE57373)),
                        onPressed: () => _deleteCabinet(cabId),
                        tooltip: "Delete",
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}