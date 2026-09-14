import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';
import 'first_aid_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  final List<Map<String, dynamic>> userDoses = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (res != null && res['full_name'] != null && mounted) {
        setState(() => userName = res['full_name']);
      }
    }
  }

  void _showAddDoseDialog() {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFFDFBF9),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Scheduled Dose",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(hintText: "Medicine name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    hintText: "Instruction (e.g. After food)",
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null)
                      setDialogState(() => selectedTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EFEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Time:"),
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      setState(() {
                        userDoses.add({
                          "name": nameCtrl.text.trim(),
                          "note": noteCtrl.text.trim().isEmpty
                              ? "As directed"
                              : noteCtrl.text.trim(),
                          "time": selectedTime.format(context),
                          "isTaken": false,
                        });
                      });
                      NotificationService().scheduleDailyDoseNotification(
                        id: userDoses.length,
                        title: "Time for ${nameCtrl.text.trim()}",
                        body: noteCtrl.text.trim().isEmpty
                            ? "Please take your dose now."
                            : noteCtrl.text.trim(),
                        time: selectedTime,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE57373),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save & Schedule Reminder"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String liveDate =
        "Today, ${DateFormat('MMM d').format(DateTime.now())}";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isEmpty
                            ? "Welcome! 👋"
                            : "Welcome, $userName! 👋",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE57373),
                        ),
                      ),
                      const Text(
                        "Home Pharmacy",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2A272A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.health_and_safety_outlined,
                      color: Color(0xFFE57373),
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Schedule",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        liveDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8D8783),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showAddDoseDialog,
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFFE57373),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                      "No doses scheduled. Tap + to add.",
                      style: TextStyle(color: Color(0xFF8D8783)),
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
                    final isTaken = dose['isTaken'] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            dose['time'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dose['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isTaken
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                Text(
                                  dose['note'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8D8783),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isTaken,
                            activeColor: const Color(0xFF2E6335),
                            onChanged: (v) =>
                                setState(() => dose['isTaken'] = v),
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
    );
  }
}
