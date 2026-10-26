import 'package:flutter/material.dart';
import '../../home/presentation/home_page.dart';

// ------------------ LIFESTYLE INFO SCREEN ------------------
class LifestyleInfoScreen extends StatefulWidget {
  const LifestyleInfoScreen({super.key});

  @override
  State<LifestyleInfoScreen> createState() => _LifestyleInfoScreenState();
}

class _LifestyleInfoScreenState extends State<LifestyleInfoScreen> {
  bool _reminders = true;
  bool _dailyCheck = true;
  bool _refillAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A5AE0), Color(0xFF8364E8)], // same gradient
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Title + subtitle
              const Text(
                "Complete Your Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Help us personalize your medication experience",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              // Thin 3-step progress bars (all filled to match the screenshot)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              // White card body
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Notification Preferences",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tile 1: Medication Reminders
                        _prefTile(
                          leading: Icons.notifications_active_outlined,
                          title: "Medication Reminders",
                          subtitle:
                              "Get notified when it's time to\ntake your medication",
                          value: _reminders,
                          onChanged: (v) => setState(() => _reminders = v),
                        ),
                        const SizedBox(height: 12),
                        // Tile 2: Daily Health Check
                        _prefTile(
                          leading: Icons.favorite_outline,
                          title: "Daily Health Check",
                          subtitle:
                              "Receive daily prompts to log\nyour health status",
                          value: _dailyCheck,
                          onChanged: (v) => setState(() => _dailyCheck = v),
                        ),
                        const SizedBox(height: 12),
                        // Tile 3: Medication Refill Alerts
                        _prefTile(
                          leading: Icons.local_pharmacy_outlined,
                          title: "Medication Refill Alerts",
                          subtitle:
                              "Get reminded when you're\nrunning low on medication",
                          value: _refillAlerts,
                          onChanged: (v) => setState(() => _refillAlerts = v),
                        ),
                        const SizedBox(height: 16),
                        // Big bottom banner inside the card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF7C6CF4), Color(0xFF9B84FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.check_circle_outline,
                                size: 36,
                                color: Colors.white,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "You're All Set!",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom buttons: Previous / Complete Setup
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Previous"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6A5AE0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          // Navigate to the medication tracker homepage
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Setup complete 🎉")),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                            (route) => false,
                          );
                        },
                        child: const Text("Complete Setup"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- UI helpers -----
  Widget _prefTile({
    required IconData leading,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // very soft shadow
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leading, color: const Color(0xFF6A5AE0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFBFC3FF),
            thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF5A67F2);
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }
}
