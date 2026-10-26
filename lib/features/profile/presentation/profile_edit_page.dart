import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../data/profile_service.dart';
import '../../../core/widgets/shared_widgets.dart';

// -------------------- PROFILE EDIT PAGE --------------------
class ProfileEditPage extends StatefulWidget {
  final UserProfile profile;

  const ProfileEditPage({super.key, required this.profile});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage>
    with SingleTickerProviderStateMixin {
  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Personal Info Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Emergency Contact Controllers
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Medical Info Controllers
  final _bloodTypeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  final _insuranceProviderController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  // Form state
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  List<String> _allergies = [];
  List<String> _medicalConditions = [];
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _populateFields();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    _insuranceProviderController.dispose();
    _insuranceNumberController.dispose();
    _medicalNotesController.dispose();
    _allergyController.dispose();
    _conditionController.dispose();
  }

  void _populateFields() {
    try {
      _firstNameController.text = widget.profile.firstName;
      _lastNameController.text = widget.profile.lastName;
      _emailController.text = widget.profile.email;
      _phoneController.text = widget.profile.phone ?? '';
      _addressController.text = widget.profile.address ?? '';
      _selectedDateOfBirth = widget.profile.dateOfBirth;
      _selectedGender = widget.profile.gender;

      _emergencyContactController.text = widget.profile.emergencyContact ?? '';
      _emergencyPhoneController.text = widget.profile.emergencyPhone ?? '';

      final medInfo = widget.profile.medicalInfo;
      if (medInfo != null) {
        _bloodTypeController.text = medInfo.bloodType ?? '';
        _heightController.text = medInfo.height?.toString() ?? '';
        _weightController.text = medInfo.weight?.toString() ?? '';
        _doctorNameController.text = medInfo.doctorName ?? '';
        _doctorPhoneController.text = medInfo.doctorPhone ?? '';
        _insuranceProviderController.text = medInfo.insuranceProvider ?? '';
        _insuranceNumberController.text = medInfo.insuranceNumber ?? '';
        _medicalNotesController.text = medInfo.notes ?? '';
        _allergies = List.from(medInfo.allergies);
        _medicalConditions = List.from(medInfo.medicalConditions);
      }
    } catch (e) {
      debugPrint('Error populating profile fields: $e');
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Gradient header with title + actions
              SizedBox(
                height: 130,
                child: CustomScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  slivers: [
                    GradientHeaderSliver(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Edit Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6A5AE0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ScrollableTabWrapper(child: _buildPersonalTab()),
                    _ScrollableTabWrapper(child: _buildEmergencyTab()),
                    _ScrollableTabWrapper(child: _buildMedicalTab()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6A5AE0),
        unselectedLabelColor: const Color(0xFF9BA1AB),
        indicatorColor: const Color(0xFF6A5AE0),
        tabs: const [
          Tab(text: 'Personal'),
          Tab(text: 'Emergency'),
          Tab(text: 'Medical'),
        ],
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@')) {
                  return 'Please enter valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildGenderField(),
            const SizedBox(height: 24),
            _buildSectionTitle('Address'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Full Address',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Emergency Contact'),
          const SizedBox(height: 8),
          const Text(
            'This person will be contacted in case of emergency',
            style: TextStyle(color: Color(0xFF9BA1AB), fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emergencyContactController,
            label: 'Contact Name',
            hint: 'e.g., John Doe',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emergencyPhoneController,
            label: 'Contact Phone',
            keyboardType: TextInputType.phone,
            hint: 'e.g., +1 (555) 123-4567',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Physical Information'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: 'Height (cm)',
                  keyboardType: TextInputType.number,
                  hint: 'e.g., 175',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  keyboardType: TextInputType.number,
                  hint: 'e.g., 70.5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bloodTypeController,
            label: 'Blood Type',
            hint: 'e.g., O+, A-, B+',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Healthcare Provider'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _doctorNameController,
            label: 'Doctor Name',
            hint: 'e.g., Dr. Sarah Smith',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _doctorPhoneController,
            label: 'Doctor Phone',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _insuranceProviderController,
            label: 'Insurance Provider',
            hint: 'e.g., Blue Cross Blue Shield',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _insuranceNumberController,
            label: 'Insurance Number',
            hint: 'Your insurance policy number',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Allergies'),
          const SizedBox(height: 16),
          _buildChipsList(
            items: _allergies,
            onRemove: (item) {
              setState(() {
                _allergies.remove(item);
              });
            },
            emptyText: 'No allergies added',
          ),
          const SizedBox(height: 8),
          _buildAddItemField(
            controller: _allergyController,
            hint: 'Add allergy (e.g., Penicillin)',
            onAdd: (value) {
              if (value.isNotEmpty && !_allergies.contains(value)) {
                setState(() {
                  _allergies.add(value);
                });
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Medical Conditions'),
          const SizedBox(height: 16),
          _buildChipsList(
            items: _medicalConditions,
            onRemove: (item) {
              setState(() {
                _medicalConditions.remove(item);
              });
            },
            emptyText: 'No conditions added',
          ),
          const SizedBox(height: 8),
          _buildAddItemField(
            controller: _conditionController,
            hint: 'Add condition (e.g., Hypertension)',
            onAdd: (value) {
              if (value.isNotEmpty && !_medicalConditions.contains(value)) {
                setState(() {
                  _medicalConditions.add(value);
                });
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Additional Notes'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _medicalNotesController,
            label: 'Medical Notes',
            maxLines: 4,
            hint: 'Any additional medical information...',
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2E2E2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date of Birth',
              style: TextStyle(fontSize: 12, color: Color(0xFF6A6A6A)),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedDateOfBirth != null
                  ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                  : 'Select date of birth',
              style: TextStyle(
                fontSize: 16,
                color: _selectedDateOfBirth != null
                    ? const Color(0xFF2E2E2E)
                    : const Color(0xFF9BA1AB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    const genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6A6A6A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genders.map((gender) {
            final isSelected = _selectedGender == gender;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = gender;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6A5AE0)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  gender,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6A6A6A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChipsList({
    required List<String> items,
    required Function(String) onRemove,
    required String emptyText,
  }) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          emptyText,
          style: const TextStyle(
            color: Color(0xFF9BA1AB),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          label: Text(item),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => onRemove(item),
          backgroundColor: const Color(0xFFE8F4FD),
          deleteIconColor: const Color(0xFF6A5AE0),
        );
      }).toList(),
    );
  }

  Widget _buildAddItemField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6A5AE0),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) {
              onAdd(value.trim());
              controller.clear();
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            onAdd(controller.text.trim());
            controller.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A5AE0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create medical info
        final medicalInfo = MedicalInfo(
          bloodType: _bloodTypeController.text.trim().isEmpty
              ? null
              : _bloodTypeController.text.trim(),
          height: _heightController.text.trim().isEmpty
              ? null
              : double.tryParse(_heightController.text.trim()),
          weight: _weightController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightController.text.trim()),
          doctorName: _doctorNameController.text.trim().isEmpty
              ? null
              : _doctorNameController.text.trim(),
          doctorPhone: _doctorPhoneController.text.trim().isEmpty
              ? null
              : _doctorPhoneController.text.trim(),
          insuranceProvider: _insuranceProviderController.text.trim().isEmpty
              ? null
              : _insuranceProviderController.text.trim(),
          insuranceNumber: _insuranceNumberController.text.trim().isEmpty
              ? null
              : _insuranceNumberController.text.trim(),
          notes: _medicalNotesController.text.trim().isEmpty
              ? null
              : _medicalNotesController.text.trim(),
          allergies: _allergies,
          medicalConditions: _medicalConditions,
        );

        // Update profile
        final updatedProfile = widget.profile.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          dateOfBirth: _selectedDateOfBirth,
          gender: _selectedGender,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          emergencyContact: _emergencyContactController.text.trim().isEmpty
              ? null
              : _emergencyContactController.text.trim(),
          emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
              ? null
              : _emergencyPhoneController.text.trim(),
          medicalInfo: medicalInfo,
        );

        await _profileService.updateProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFF2EAC5F),
            ),
          );

          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ScrollableTabWrapper extends StatelessWidget {
  final Widget child;
  const _ScrollableTabWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }
}
