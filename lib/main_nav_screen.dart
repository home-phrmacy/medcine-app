import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/cabinet_screen.dart';
import '../screens/add_screen.dart';
import '../screens/first_aid_screen.dart';
import '../screens/history_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  // 0: Home, 1: Cabinet, 2: Add, 3: First Aid, 4: History
  final List<Widget> _screens = const [
    HomeScreen(),
    CabinetScreen(),
    AddScreen(),
    FirstAidScreen(),
    HistoryScreen(),
  ];

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? const Color(0xFFE57373) : Colors.grey.shade400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFE57373) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F1),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. أقصى اليسار: Cabinet
            _buildNavItem(
              index: 1,
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2_rounded,
              label: 'Cabinet',
            ),

            // 2. اليسار: Add
            _buildNavItem(
              index: 2,
              icon: Icons.add_circle_outline_rounded,
              activeIcon: Icons.add_circle_rounded,
              label: 'Add',
            ),

            // 3. الوسط تماماً: زر الهوم الدائري البارز
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 0),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFE57373),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40E57373),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // 4. اليمين: First Aid
            _buildNavItem(
              index: 3,
              icon: Icons.health_and_safety_outlined,
              activeIcon: Icons.health_and_safety_rounded,
              label: 'Home Emergency',
            ),

            // 5. أقصى اليمين: History
            _buildNavItem(
              index: 4,
              icon: Icons.history_rounded,
              activeIcon: Icons.history_toggle_off_rounded,
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}