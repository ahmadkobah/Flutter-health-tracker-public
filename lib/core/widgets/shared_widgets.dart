import 'package:flutter/material.dart';

// ============= SHARED WIDGETS =============

/// Gradient header widget used across the app
class GradientHeaderSliver extends StatelessWidget {
  final Widget child;
  final double? minHeight;
  const GradientHeaderSliver({super.key, required this.child, this.minHeight});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A5AE0), Color(0xFF8364E8)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Frosted glass icon button
class FrostIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const FrostIcon({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: iconWidget);
    }

    return iconWidget;
  }
}

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  const BottomNav({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BottomNavigationBar(
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medication_liquid_rounded),
                label: 'Medications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_rounded),
                label: 'Nutrition',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services_rounded),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
            currentIndex: currentIndex,
            onTap: onTap,
            selectedItemColor: const Color(0xFF4F46E5),
            unselectedItemColor: const Color(0xFF9CA3AF),
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class MedAvatar extends StatelessWidget {
  const MedAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          size: 22,
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }
}

class CheckBox extends StatelessWidget {
  final bool ticked;
  const CheckBox({super.key, required this.ticked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: ticked ? const Color(0xFF10B981) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ticked ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
          width: 2,
        ),
        boxShadow: [
          if (ticked)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ticked
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}
