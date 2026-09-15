import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phrm_app/screens/cabinet_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  List<Map<String, dynamic>> userDoses = [];
  List<Map<String, dynamic>> cabinetsList = [];
  int totalCabinetsCount = 0;
  final Set<String> _takenMedicineIds = {};

  bool _isLoadingData = true;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadAllScreenData();
  }

  Future<void> _loadAllScreenData() async {
    final user = supabase.auth.currentUser;

    // 1. جلب اسم المستخدم
    String detectedName = "";
    if (user != null) {
      final meta = user.userMetadata;
      if (meta != null) {
        detectedName = meta['full_name']?.toString() ??
            meta['name']?.toString() ??
            meta['user_name']?.toString() ??
            "";
      }

      if (detectedName.isEmpty) {
        try {
          final profileRes = await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .maybeSingle();
          if (profileRes != null && profileRes['full_name'] != null) {
            detectedName = profileRes['full_name'].toString();
          }
        } catch (_) {}
      }
    }

    // 2. جلب الأدوية
    List<Map<String, dynamic>> allMeds = [];
    try {
      var medQuery = supabase.from('medicines').select('*');
      if (user != null) {
        medQuery = medQuery.or('user_id.eq.${user.id},user_id.is.null');
      }
      final medRes = await medQuery;
      if (medRes is List) {
        allMeds = List<Map<String, dynamic>>.from(medRes);
      }
    } catch (_) {}

    // 3. جلب الكباين وحساب عدد أدويتها
    List<Map<String, dynamic>> loadedCabinets = [];
    try {
      var cabQuery = supabase.from('cabinets').select('id, name');
      if (user != null) {
        cabQuery = cabQuery.or('user_id.eq.${user.id},user_id.is.null');
      }
      final cabRes = await cabQuery.order('created_at', ascending: true);

      if (cabRes is List) {
        final Set<String> seen = {};
        for (var cab in cabRes) {
          final cId = cab['id'].toString();
          if (seen.contains(cId)) continue;
          seen.add(cId);

          final count = allMeds.where((m) {
            final mCab = m['cabinet_id']?.toString();
            if (mCab == cId) return true;
            if (mCab == null && cabRes.length == 1) return true;
            return false;
          }).length;

          loadedCabinets.add({
            'id': cId,
            'name': cab['name'] ?? 'Cabinet',
            'count': count,
          });
        }
      }
    } catch (_) {}

    // 4. جلب الجرعات المأخوذة اليوم من dose_logs
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentDayCode = weekdays[now.weekday - 1];
    final Set<String> takenIds = {};

    try {
      var logsQuery = supabase.from('dose_logs').select('medicine_id').eq('taken_date', todayStr);
      if (user != null) {
        logsQuery = logsQuery.or('user_id.eq.${user.id},user_id.is.null');
      }
      final logsRes = await logsQuery;
      if (logsRes is List) {
        for (var row in logsRes) {
          if (row['medicine_id'] != null) {
            takenIds.add(row['medicine_id'].toString());
          }
        }
      }
    } catch (_) {}

    // 5. بناء قائمة جرعات اليوم
    List<Map<String, dynamic>> todayDoses = [];
    final todayDateOnly = DateTime(now.year, now.month, now.day);

    for (var med in allMeds) {
      final isChronic = med['is_chronic'] == true;
      final startStr = med['start_date']?.toString();
      final endStr = med['end_date']?.toString() ?? med['course_end_date']?.toString();

      if (startStr != null && startStr.isNotEmpty) {
        final start = DateTime.tryParse(startStr);
        if (start != null && todayDateOnly.isBefore(DateTime(start.year, start.month, start.day))) {
          continue;
        }
      }

      if (!isChronic && endStr != null && endStr.isNotEmpty) {
        final end = DateTime.tryParse(endStr);
        if (end != null && todayDateOnly.isAfter(DateTime(end.year, end.month, end.day))) {
          continue;
        }
      }

      final dynamic rawDays = med['notification_days'] ?? med['reminder_days'] ?? med['days'];
      List daysList = [];
      if (rawDays is List) {
        daysList = rawDays;
      }

      bool isScheduledForToday = true;
      if (daysList.isNotEmpty) {
        isScheduledForToday = daysList.any((d) =>
            d.toString().trim().toLowerCase().startsWith(currentDayCode.toLowerCase()));
      }

      if (isScheduledForToday) {
        final mId = med['id'].toString();
        final rawTimes = med['notification_times'] ?? med['dose_times'] ?? [];
        String timeStr = "08:00 AM";
        if (rawTimes is List && rawTimes.isNotEmpty) {
          timeStr = rawTimes.first.toString();
        }

        todayDoses.add({
          'medicine_id': mId,
          'name': med['name']?.toString() ?? 'Medicine',
          'note': med['instructions']?.toString() ?? 'Scheduled dose',
          'time': timeStr,
          'isTaken': takenIds.contains(mId),
        });
      }
    }

    if (mounted) {
      setState(() {
        userName = detectedName;
        cabinetsList = loadedCabinets;
        totalCabinetsCount = loadedCabinets.length; // عدد الكباين الفعلية (1)
        userDoses = todayDoses;
        _takenMedicineIds.clear();
        _takenMedicineIds.addAll(takenIds);
        _isLoadingData = false;
      });
    }
  }

  // عند الضغط على علامة الصح
  Future<void> _toggleDose(int index, bool val) async {
    if (index >= userDoses.length) return;

    final dose = userDoses[index];
    final medicineId = dose['medicine_id']?.toString();
    if (medicineId == null) return;

    final user = supabase.auth.currentUser;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // تثبيت علامة الصح في الواجهة مباشرة
    setState(() {
      dose['isTaken'] = val;
      if (val) {
        _takenMedicineIds.add(medicineId);
      } else {
        _takenMedicineIds.remove(medicineId);
      }
    });

    try {
      if (val) {
        // تسجيل الجرعة في dose_logs لترتفع النسبة في الهيستوري فوراً
        await supabase.from('dose_logs').insert({
          'medicine_id': medicineId,
          'user_id': user?.id,
          'taken_date': todayStr,
          'is_taken': true,
        });
      } else {
        var delQuery = supabase
            .from('dose_logs')
            .delete()
            .eq('medicine_id', medicineId)
            .eq('taken_date', todayStr);
        if (user != null) {
          delQuery = delQuery.eq('user_id', user.id);
        }
        await delQuery;
      }
    } catch (e) {
      // لا نلغي الصح من الشاشة حتى لو كان جدول logs يطلب شروط إضافية
      debugPrint("Log error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String liveDate =
        "Today, ${DateFormat('MMM d').format(DateTime.now())}";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 70,
        title: const Text(
          "Home Pharmacy",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A272A),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE57373)),
              )
            : RefreshIndicator(
                color: const Color(0xFFE57373),
                onRefresh: _loadAllScreenData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isEmpty ? "Welcome! 👋" : "Welcome, $userName! 👋",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // شريط الكباين
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cabinetsList.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CabinetScreen(),
                                    ),
                                  ).then((_) => _loadAllScreenData());
                                },
                                child: _CabinetItemCard(
                                  icon: Icons.all_inbox_rounded,
                                  iconColor: const Color(0xFFE57373),
                                  label: "All Cabinets",
                                  count: totalCabinetsCount, // يعرض عدد الكباين الفعلية (1)
                                  badgeColor: const Color(0xFFE57373),
                                ),
                              );
                            }

                            final cab = cabinetsList[index - 1];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CabinetScreen(
                                      initialCabinetId: cab['id'],
                                      initialCabinetName: cab['name'],
                                    ),
                                  ),
                                ).then((_) => _loadAllScreenData());
                              },
                              child: _CabinetItemCard(
                                icon: Icons.folder_outlined,
                                iconColor: const Color(0xFFCC877B),
                                label: cab['name'] ?? 'Cabinet',
                                count: cab['count'] ?? 0, // عدد أدوية my meds (2)
                                badgeColor: const Color(0xFFF2A272),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // جدول اليوم
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Schedule",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          Text(
                            liveDate,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8D8783),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (userDoses.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFBF9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              "No doses scheduled for today.",
                              style: TextStyle(
                                color: Color(0xFF8D8783),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userDoses.length,
                          itemBuilder: (ctx, idx) {
                            final dose = userDoses[idx];
                            final isTaken = dose['isTaken'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFBF9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    dose['time'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dose['name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2D3142),
                                            decoration: isTaken
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dose['note'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8D8783),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // المربع يتفعل بالضغط عليه أو على السطر بالكامل
                                  Checkbox(
                                    value: isTaken,
                                    activeColor: const Color(0xFFE57373),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) {
                                      if (v != null) {
                                        _toggleDose(idx, v);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _CabinetItemCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int? count;
  final Color badgeColor;

  const _CabinetItemCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.count,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}