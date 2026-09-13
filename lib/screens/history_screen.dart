import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int selectedDay = 0;
  final List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("History & Adherence", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFDFBF9), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Text("100%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E6335))),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Weekly Adherence", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("All planned doses taken", style: TextStyle(fontSize: 11, color: Color(0xFF8D8783))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(days.length, (i) {
                  final isSelected = selectedDay == i;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDay = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE57373) : const Color(0xFFFDFBF9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(days[i], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text("Completed Courses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No archived courses yet.", style: TextStyle(color: Color(0xFF8D8783))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}