import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/profile_service.dart';
import 'profile_edit_page.dart';
import '../../appointments/presentation/doctor_appointment_page.dart';
import '../../auth/presentation/splash_screen.dart';
import '../../home/presentation/home_page.dart';
import '../../medications/presentation/medication_list_page.dart';
import '../../nutrition/presentation/nutrition_schedule_page.dart';
import '../../settings/presentation/settings_page.dart';

// -------------------- PROFILE PAGE --------------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = ProfileService();
  UserProfile? _profile;
  bool _isLoading = true;
  double _completeness = 0.0;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _insights = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await _profileService.initializeSampleProfile();
      final profile = await _profileService.getCurrentProfile();
      final completeness = await _profileService.getProfileCompleteness();
      final stats = await _profileService.getProfileStats();
      final insights = await _profileService.getHealthInsights();

      setState(() {
        _profile = profile;
        _completeness = completeness;
        _stats = stats;
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      // Navigate to profile creation page if no profile exists
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileEditPage(
              profile: UserProfile(
                id: '',
                firstName: '',
                lastName: '',
                email: '',
                phone: '',
                dateOfBirth: null,
                gender: '',
                profileImagePath: null,
                address: '',
                emergencyContact: '',
                emergencyPhone: '',
                medicalInfo: null,
                preferences: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [_buildGradientHeaderSection(), _buildProfileContent()],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 4, // Profile tab
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MedicationListPage()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => NutritionSchedulePage(userId: 'your_user_id'),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DoctorAppointmentPage(userId: 'your_user_id'),
              ),
            );
          } else if (index == 4) {
            // Already on Profile page
          }
        },
      ),
    );
  }

  // New gradient section that only covers the header + card area and scrolls away
  Widget _buildGradientHeaderSection() {
    return SliverToBoxAdapter(
      child: Container(
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
        child: Column(
          children: [
            // Reuse header builder content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _editProfile,
                            icon: const Icon(Icons.edit, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildProfileAvatar(),
          const SizedBox(height: 16),
          Text(
            (_profile!.firstName.isNotEmpty || _profile!.lastName.isNotEmpty)
                ? _profile!.fullName.trim()
                : 'No Name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _profile!.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildCompletenessIndicator(_completeness),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: _profile!.profileImagePath != null
                ? NetworkImage(_profile!.profileImagePath!)
                : null,
            child: _profile!.profileImagePath == null
                ? Text(
                    (_profile!.firstName.isNotEmpty
                            ? _profile!.firstName[0]
                            : (_profile!.lastName.isNotEmpty
                                  ? _profile!.lastName[0]
                                  : '?')) +
                        (_profile!.lastName.isNotEmpty
                            ? _profile!.lastName[0]
                            : ''),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A5AE0),
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _editProfilePicture,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletenessIndicator(double completeness) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Completeness',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(completeness * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completeness,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildMedicalInfoSection(),
              const SizedBox(height: 24),
              _buildEmergencyContactSection(),
              const SizedBox(height: 24),
              _buildHealthInsightsSection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 100), // For bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Age', '${_stats['age'] ?? 'N/A'}', Icons.cake),
              _buildStatItem(
                'Member',
                '${_stats['memberSince'] ?? 0}d',
                Icons.calendar_today,
              ),
              _buildStatItem(
                'Complete',
                '${_stats['completeness'] ?? 0}%',
                Icons.check_circle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9BA1AB)),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildInfoSection(
      title: 'Personal Information',
      icon: Icons.person,
      children: [
        _buildInfoRow('Full Name', _profile!.fullName),
        _buildInfoRow('Email', _profile!.email),
        _buildInfoRow('Phone', _profile!.phone ?? 'Not provided'),
        _buildInfoRow(
          'Date of Birth',
          _profile!.dateOfBirth != null
              ? '${_profile!.dateOfBirth!.day}/${_profile!.dateOfBirth!.month}/${_profile!.dateOfBirth!.year}'
              : 'Not provided',
        ),
        _buildInfoRow('Gender', _profile!.gender ?? 'Not specified'),
        _buildInfoRow('Address', _profile!.address ?? 'Not provided'),
      ],
    );
  }

  Widget _buildMedicalInfoSection() {
    final medInfo = _profile!.medicalInfo;

    return _buildInfoSection(
      title: 'Medical Information',
      icon: Icons.medical_services,
      children: [
        _buildInfoRow('Blood Type', medInfo?.bloodType ?? 'Unknown'),
        _buildInfoRow(
          'Height',
          medInfo?.height != null
              ? '${medInfo!.height!.toStringAsFixed(0)} cm'
              : 'Not provided',
        ),
        _buildInfoRow(
          'Weight',
          medInfo?.weight != null
              ? '${medInfo!.weight!.toStringAsFixed(1)} kg'
              : 'Not provided',
        ),
        if (medInfo?.bmi != null)
          _buildInfoRow(
            'BMI',
            '${medInfo!.bmi!.toStringAsFixed(1)} (${medInfo.bmiCategory})',
          ),
        _buildInfoRow('Primary Doctor', medInfo?.doctorName ?? 'Not assigned'),
        _buildInfoRow('Doctor Phone', medInfo?.doctorPhone ?? 'Not provided'),
        _buildInfoRow(
          'Insurance',
          medInfo?.insuranceProvider ?? 'Not provided',
        ),
        if (medInfo?.allergies.isNotEmpty == true)
          _buildInfoRow('Allergies', medInfo!.allergies.join(', ')),
        if (medInfo?.medicalConditions.isNotEmpty == true)
          _buildInfoRow('Conditions', medInfo!.medicalConditions.join(', ')),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    return _buildInfoSection(
      title: 'Emergency Contact',
      icon: Icons.emergency,
      children: [
        _buildInfoRow(
          'Contact Name',
          _profile!.emergencyContact ?? 'Not provided',
        ),
        _buildInfoRow(
          'Contact Phone',
          _profile!.emergencyPhone ?? 'Not provided',
        ),
      ],
    );
  }

  Widget _buildHealthInsightsSection() {
    if (_insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildInfoSection(
      title: 'Health Insights',
      icon: Icons.insights,
      children: [
        if (_insights['bmi'] != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _insights['bmi']['isHealthy']
                  ? const Color(0xFFE8F5E8)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _insights['bmi']['isHealthy']
                      ? Icons.check_circle
                      : Icons.warning,
                  color: _insights['bmi']['isHealthy']
                      ? const Color(0xFF2EAC5F)
                      : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'BMI: ${_insights['bmi']['value']} (${_insights['bmi']['category']})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_insights['recommendations'] != null &&
            (_insights['recommendations'] as List).isNotEmpty) ...[
          const Text(
            'Recommendations:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...(_insights['recommendations'] as List<String>).map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(rec, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6A5AE0), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6A6A6A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2E2E2E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5AE0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Export Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutConfirmation,
            icon: const Icon(Icons.logout, color: Colors.orange),
            label: const Text(
              'Log Out',
              style: TextStyle(color: Colors.orange),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text(
              'Delete Profile',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditPage(profile: _profile!)),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  void _editProfilePicture() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (_profile!.profileImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _takePicture() {
    // In a real app, this would use image_picker to take a photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera functionality would be implemented here'),
      ),
    );
  }

  void _pickFromGallery() {
    // In a real app, this would use image_picker to select from gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery picker would be implemented here')),
    );
  }

  void _removeProfilePicture() async {
    try {
      await _profileService.updateProfilePicture('');
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportData() async {
    try {
      final data = await _profileService.exportProfileData();
      // In a real app, this would save the data to a file or share it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile data exported (${data.length} fields)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out? You will need to sign in again to access your data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _profileService.logout();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Profile'),
          content: const Text(
            'Are you sure you want to delete your profile? This action cannot be undone and will remove all your data including medications and settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProfile();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProfile() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _profileService.deleteProfile();

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to splash screen to handle re-authentication
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
