import 'package:flutter/material.dart';
import 'medical_info_screen.dart';

// ------------------ COMPLETE PROFILE SCREEN ------------------
class CompleteProfileScreen extends StatelessWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A5AE0), Color(0xFF8364E8)], // Purple gradient
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
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
              const SizedBox(height: 20),
              // Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Center(
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundColor: Color.fromARGB(
                                  255,
                                  176,
                                  202,
                                  226,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Color.fromARGB(255, 90, 105, 197),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {},
                                child: const Text("Tap to change avatar"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Phone Number
                        _buildTextField(
                          hint: "",
                          label: "Phone Number",
                          icon: Icons.phone,
                        ),
                        const SizedBox(height: 12),
                        // Age + Gender
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                hint: "",
                                label: "Age",
                                icon: Icons.cake,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                label: "Gender",
                                icon: Icons.person,
                                value: "Female",
                                items: const ["Male", "Female"],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Height + Weight
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                hint: "",
                                label: "Height (cm)",
                                icon: Icons.height,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                hint: "",
                                label: "Weight (kg)",
                                icon: Icons.monitor_weight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Blood Type
                        _buildDropdown(
                          label: "Blood Type",
                          icon: Icons.bloodtype,
                          value: "AB+",
                          items: const [
                            "A+",
                            "A-",
                            "B+",
                            "B-",
                            "AB+",
                            "AB-",
                            "O+",
                            "O-",
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Emergency Contact
                        const Text(
                          " Emergency Contact",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(221, 30, 29, 29),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Emergency Contact Name
                        _buildTextField(
                          hint: "Contact Name",
                          label: "Emergency Contact",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        // Emergency Contact Phone
                        _buildTextField(
                          hint: "Contact Phone",
                          label: "",
                          icon: Icons.phone_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Next Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicalInfoScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Next",
                    style: TextStyle(fontSize: 16, color: Color(0xFF6A5AE0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable TextField
  Widget _buildTextField({
    required String hint,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        labelText: label.isNotEmpty ? label : null,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Reusable Dropdown
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      initialValue: value,
      items: items.map((String val) {
        return DropdownMenuItem<String>(value: val, child: Text(val));
      }).toList(),
      onChanged: (val) {},
    );
  }
}
