import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  late String _selectedDay;
  late final String _actualToday;

  bool _isLoading = true;
  List<Map<String, dynamic>> _activeMedicines = [];
  List<Map<String, dynamic>> _completedMedicines = [];
  Set<String> _takenMedicineIds = {};

  int _adherenceRate = 0;

  @override
  void initState() {
    super.initState();
    _initCurrentDay();
    _loadScreenData();
  }

  void _initCurrentDay() {
    final int weekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    final Map<int, String> dayMap = {
      7: 'Sun',
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
    };
    _actualToday = dayMap[weekday] ?? 'Tue';
    _selectedDay = _actualToday;
  }

  Color _getAdherenceColor(int rate) {
    if (rate >= 80) return const Color(0xFF4CAF50);
    if (rate >= 40) return const Color(0xFFFFA726);
    return const Color(0xFFE57373);
  }
  
  List<Map<String, dynamic>> _medicinesForDay(String day) {
    return _activeMedicines.where((med) {
      final rawDays = med['notification_days'];
      if (rawDays == null) return true;
      if (rawDays is List) {
        if (rawDays.isEmpty) return true;
        return rawDays.map((d) => d.toString()).contains(day);
      }
      return true;
    }).toList();
  }

 Future<void> _loadScreenData() async {
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    try {
      // 1 . جلب كل الأدوية
      var medQuery = client.from('medicines').select('*');
      if (user != null) {
        medQuery = medQuery.or('user_id.eq.${user.id},user_id.is.null');
      }
      final medRes = await medQuery.order('created_at', ascending: false);
      final List<Map<String, dynamic>> allMeds = List<Map<String, dynamic>>.from(medRes as List);

      // 2 . فحص الأدوية المنتهية والنشطة بناء على تاريخ اليوم
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final List<Map<String, dynamic>> active = [];
      final List<Map<String, dynamic>> completed = [];

      for (var med in allMeds) {
        final isChronic = med['is_chronic'] == true;
        final endStr = med['end_date']?.toString() ?? med['course_end_date']?.toString();

        bool isEnded = false;
        if (!isChronic && endStr != null && endStr.isNotEmpty) {
          final end = DateTime.tryParse(endStr);
          if (end != null && todayDate.isAfter(DateTime(end.year, end.month, end.day))) {
            isEnded = true;
          }
        }

        if (isEnded) {
          completed.add(med);
        } else {
          active.add(med);
        }
      }

      // 3 . جلب الجرعات التي وُضع عليها صح بناءً على اليوم المحدد بدقة
      DateTime nowObj = DateTime.now();
      List<String> daysList = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      int todayIndex = daysList.indexOf(_actualToday);
      int selectedIndex = daysList.indexOf(_selectedDay);
      int dayDifference = selectedIndex - todayIndex;
      
      DateTime selectedDateObj = nowObj.add(Duration(days: dayDifference));
      String selectedDateStr = "${selectedDateObj.year}-${selectedDateObj.month.toString().padLeft(2, '0')}-${selectedDateObj.day.toString().padLeft(2, '0')}";

      var logQuery = client.from('dose_logs').select('medicine_id');
      if (user != null) {
        logQuery = logQuery.or('user_id.eq.${user.id},user_id.is.null');
      }
      final logRes = await logQuery.eq('taken_date', selectedDateStr);

      final Set<String> takenIds = {};
      if (logRes is List) {
        for (var row in logRes) {
          if (row['medicine_id'] != null) {
            takenIds.add(row['medicine_id'].toString());
          }
        }
      }

      // 4 . حساب النسبة المئوية بدقة بناءً على سجلات التاريخ المحدد فقط
      int calculatedRate = 0;
      if (active.isNotEmpty) {
        int takenCount = 0;
        for (var m in active) {
          if (takenIds.contains(m['id'].toString())) {
            takenCount++;
          }
        }
        calculatedRate = ((takenCount / active.length) * 100).round();
      } else {
        calculatedRate = 0;
      }

      if (mounted) {
        setState(() {
          _activeMedicines = active;
          _completedMedicines = completed;
          _takenMedicineIds = takenIds;
          _adherenceRate = calculatedRate;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

    
  @override
  Widget build(BuildContext context) {
    final adherenceColor = _getAdherenceColor(_adherenceRate);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'History & Adherence',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE57373)))
          : RefreshIndicator(
              color: const Color(0xFFE57373),
              onRefresh: _loadScreenData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة النسبة الديناميكية
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$_adherenceRate%',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: adherenceColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDay == _actualToday ? "Today's Adherence" : "$_selectedDay Adherence",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _adherenceRate == 100
                                    ? 'All planned doses taken'
                                    : '$_adherenceRate% of scheduled doses completed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // شريط الأيام
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _days.map((day) {
                          final isSelected = _selectedDay == day;
                          final isToday = _actualToday == day;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () => setState(() => _selectedDay = day),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 52,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE57373) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE57373)
                                        : (isToday
                                            ? const Color(0xFFE57373).withOpacity(0.5)
                                            : Colors.grey.shade200),
                                    width: isToday && !isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  day,
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
                    ),
                    const SizedBox(height: 20),

                    Text(
                      _selectedDay == _actualToday
                          ? "Today's Medicines ($_selectedDay)"
                          : "$_selectedDay Schedule",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_medicinesForDay(_selectedDay).isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(
                          child: Text(
                            'No active medications currently.',
                            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _medicinesForDay(_selectedDay).length,
                        itemBuilder: (context, index) {
                          final med = _medicinesForDay(_selectedDay)[index];
                          final medId = med['id'].toString();
                          final isTaken = _takenMedicineIds.contains(medId);
                          final rawTimes = med['notification_times'] ?? med['dose_times'] ?? [];
                          final timeStr = (rawTimes is List && rawTimes.isNotEmpty)
                              ? rawTimes.first.toString()
                              : '08:00 AM';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF0ED),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isTaken ? Icons.check_circle_rounded : Icons.medication_outlined,
                                    color: isTaken ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med['name']?.toString() ?? 'Unnamed Medicine',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2D3142),
                                          decoration: isTaken ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    const Text(
                      'Completed Courses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_completedMedicines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: Text(
                            'No archived courses yet.',
                            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _completedMedicines.length,
                        itemBuilder: (context, index) {
                          final course = _completedMedicines[index];
                          final startDate = course['start_date']?.toString() ?? 'N/A';
                          final endDate = course['end_date']?.toString() ?? 'N/A';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF81C784),
                                  size: 26,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course['name']?.toString() ?? 'Medicine',
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3142),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined,
                                              size: 13, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Started: $startDate",
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.event_available_outlined,
                                              size: 13, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Ended: $endDate",
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}