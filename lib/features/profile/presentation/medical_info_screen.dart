import 'package:flutter/material.dart';
import 'lifestyle_info_screen.dart';

// ------------------ MEDICAL INFORMATION SCREEN ------------------
class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  final _allergyCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _doctorNameCtrl = TextEditingController();
  final _doctorPhoneCtrl = TextEditingController();

  @override
  void dispose() {
    _allergyCtrl.dispose();
    _conditionsCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6A5AE0),
              Color(0xFF8364E8),
            ], // same purple gradient
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
              // Simple step indicator (to match the thin bars in the mock)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Card body
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
                        _sectionTitle("Medical Information"),
                        // Known Allergies (tile-like input)
                        _outlinedTile(
                          icon: Icons.warning_amber_outlined,
                          label: "Known Allergies",
                          child: _multilineField(
                            controller: _allergyCtrl,
                            hint: "e.g., Penicillin, Nuts",
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Medical Conditions (tile-like input)
                        _outlinedTile(
                          icon: Icons.medical_services_outlined,
                          label: "Medical Conditions",
                          child: _multilineField(
                            controller: _conditionsCtrl,
                            hint: "e.g., Asthma, Diabetes",
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionTitle("Primary Doctor"),
                        const SizedBox(height: 8),
                        // Doctor Name
                        _textField(
                          controller: _doctorNameCtrl,
                          prefixIcon: Icons.local_hospital_outlined,
                          hint: "Doctor Name",
                        ),
                        const SizedBox(height: 12),
                        // Doctor Phone
                        _textField(
                          controller: _doctorPhoneCtrl,
                          prefixIcon: Icons.phone_outlined,
                          hint: "Doctor Phone",
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        // Health Tip card (info tile)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE6E9FF)),
                          ),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.health_and_safety,
                                size: 26,
                                color: Color(0xFF5A67F2),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Health Tip",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5A67F2),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Providing accurate medical information helps us give you better "
                                "medication reminders and health insights.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom actions: Previous / Next
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
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
                        onPressed: _handleNext,
                        child: const Text("Next"),
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

  // ---------- helpers (UI) ----------
  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    ),
  );

  Widget _outlinedTile({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5A67F2)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _multilineField({
    required TextEditingController controller,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required IconData prefixIcon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: Colors.blueGrey),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleNext() {
    // Navigate to LifestyleInfoScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LifestyleInfoScreen()),
    );
  }
}
