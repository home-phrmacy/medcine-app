import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/cabinet_screen.dart';
import 'screens/add_screen.dart';
import 'screens/history_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CabinetScreen(),
    AddScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1ED),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 1, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: "Cabinet"),
            _buildNavItem(index: 2, icon: Icons.add_rounded, activeIcon: Icons.add_circle_rounded, label: "Add"),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 0),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFE57373),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x40E57373), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
              ),
            ),
            _buildNavItem(index: 3, icon: Icons.history_rounded, activeIcon: Icons.history_edu_rounded, label: "History"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required IconData activeIcon, required String label}) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFBEBEA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(activeIcon, size: 20, color: const Color(0xFFE57373)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE57373))),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF8D8783)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF8D8783))),
              ],
            ),
    );
  }
}