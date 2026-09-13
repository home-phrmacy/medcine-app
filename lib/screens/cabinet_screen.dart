import 'package:flutter/material.dart';

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  final List<Map<String, dynamic>> userCabinets = [];
  String? selectedCabinet;

  void _createCabinet() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Cabinet"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Cabinet Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() {
                  userCabinets.add({"name": ctrl.text.trim(), "items": []});
                  selectedCabinet = ctrl.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

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
              const Text("Medicine Cabinet", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: selectedCabinet,
                    hint: const Text("Choose Cabinet"),
                    items: userCabinets.map((c) {
                      return DropdownMenuItem<String>(value: c['name'] as String, child: Text(c['name'] as String));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedCabinet = v),
                  ),
                  IconButton(onPressed: _createCabinet, icon: const Icon(Icons.create_new_folder, color: Color(0xFFE57373))),
                ],
              ),
              const Expanded(
                child: Center(
                  child: Text("No medicines added to this cabinet yet.", style: TextStyle(color: Color(0xFF8D8783))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}