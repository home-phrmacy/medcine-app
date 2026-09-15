import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FirstAidScreen extends StatelessWidget {
  const FirstAidScreen({super.key});

  // دالة الاتصال المباشر برقم الطوارئ
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (_) {
      // التعامل مع بيئة الويب أو في حال عدم توفر تطبيق اتصال
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر العلوي
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFE57373),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Home Emergency Guide',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Instant protocols & emergency hotlines',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // بطاقتي الاتصال السريع (قابلة للنقر للاتصال المباشر)
              Row(
                children: [
                  // كارد الإسعاف 997
                  Expanded(
                    child: InkWell(
                      onTap: () => _makePhoneCall('997'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE57373),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33E57373),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.emergency, color: Colors.white, size: 28),
                            SizedBox(height: 8),
                            Text(
                              'Ambulance',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '997',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // كارد الاستشارات والسموم 937
                  Expanded(
                    child: InkWell(
                      onTap: () => _makePhoneCall('937'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.support_agent_rounded, color: Color(0xFF2D3142), size: 28),
                            SizedBox(height: 8),
                            Text(
                              'Poison / Advice',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '937',
                              style: TextStyle(
                                color: Color(0xFF2D3142),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // عنوان القسم
              const Text(
                'Home Emergency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 14),

              // قائمة الـ 5 كاردز المباشرة بدون سحب
              ...[
                {
                  'title': 'Accidental Overdose / Poisoning',
                  'subtitle': 'Swallowed wrong pills or chemicals',
                  'action': 'Do NOT induce vomiting. Call 937 immediately and keep the medicine box.',
                  'icon': Icons.medical_services_outlined,
                },
                {
                  'title': 'Burns & Scalds',
                  'subtitle': 'Thermal or chemical contact',
                  'action': 'Cool under running tap water for 15-20 min. Do NOT apply ice, oil, or paste.',
                  'icon': Icons.local_fire_department_outlined,
                },
                {
                  'title': 'Choking & Blocked Airway',
                  'subtitle': 'Sudden inability to breathe or speak',
                  'action': 'Give 5 firm back blows between shoulder blades, then 5 abdominal thrusts.',
                  'icon': Icons.warning_amber_rounded,
                },
                {
                  'title': 'Severe Cuts & Bleeding',
                  'subtitle': 'Deep wounds or heavy bleeding',
                  'action': 'Apply firm direct pressure with clean cloth. Elevate injured area above heart.',
                  'icon': Icons.healing_outlined,
                },
                {
                  'title': 'Fainting & Dizziness',
                  'subtitle': 'Sudden loss of consciousness',
                  'action': 'Lay flat on back, elevate feet 30 cm, loosen tight clothing, ensure fresh air.',
                  'icon': Icons.accessibility_new_rounded,
                },
              ].map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFFE57373),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F7F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['action'] as String,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE57373),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}