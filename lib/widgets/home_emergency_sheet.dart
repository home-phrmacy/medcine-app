import 'package:flutter/material.dart';

class HomeEmergencySheet extends StatelessWidget {
  const HomeEmergencySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HomeEmergencySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F1ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFF8D8783).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFBEBEA), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFFE57373), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Home Emergency Guide", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF2A272A))),
                    SizedBox(height: 2),
                    Text("Instant protocols & emergency hotlines", style: TextStyle(fontSize: 11, color: Color(0xFF8D8783))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE57373),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFE57373).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                              SizedBox(height: 6),
                              Text("Ambulance", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                              Text("997", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFBF9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFEFE8E3), width: 1.2),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.support_agent_rounded, color: Color(0xFF2E6335), size: 24),
                              SizedBox(height: 6),
                              Text("Poison / Advice", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8D8783))),
                              Text("937", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2E6335))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("First Aid Protocols", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2A272A))),
                  const SizedBox(height: 10),
                  _buildProtocolItem(
                    icon: Icons.medication_liquid_rounded,
                    title: "Accidental Overdose / Poisoning",
                    subtitle: "Swallowed wrong pills or chemicals",
                    steps: [
                      "Do NOT induce vomiting unless instructed by a medical doctor.",
                      "Keep the medicine package near you to state active ingredients.",
                      "Immediately call 937 for toxicology guidance.",
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildProtocolItem(
                    icon: Icons.local_fire_department_rounded,
                    title: "Burns & Scalds",
                    subtitle: "Thermal or chemical contact",
                    steps: [
                      "Cool the burn with cool running water for 10 to 20 minutes.",
                      "Never apply ice, toothpaste, or oil.",
                      "Cover loosely with sterile plastic cling film or clean cloth.",
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolItem({required IconData icon, required String title, required String subtitle, required List<String> steps}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF5EFEB), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFFE57373), size: 18),
          ),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2A272A))),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF8D8783))),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.bold)),
                      Expanded(child: Text(step, style: const TextStyle(fontSize: 11, color: Color(0xFF2A272A)))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}