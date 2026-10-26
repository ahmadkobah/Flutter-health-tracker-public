import "dart:math";
import "package:flutter/material.dart";
import '../../../core/models/models.dart';
import "../../../core/services/firestore_service.dart";
import "../../auth/data/auth_service.dart";

/// Service for managing user profile operations
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  UserProfile? _currentProfile;

  /// Log out user and clear profile cache
  Future<void> logout() async {
    try {
      await _authService.signOut();
      clearCache();
    } catch (e) {
      debugPrint('[ProfileService] Error during logout: $e');
      throw Exception('Failed to log out: $e');
    }
  }

  /// Get current user profile from cache or Firestore
  Future<UserProfile?> getCurrentProfile() async {
    if (_currentProfile != null) {
      return _currentProfile;
    }

    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        _currentProfile = null;
        return null;
      }

      final profile = await _firestoreService.getUserProfile();
      _currentProfile = profile;
      return _currentProfile;
    } catch (e) {
      debugPrint('[ProfileService] Error getting current profile: $e');
      _currentProfile = null;
      return null;
    }
  }

  /// Update user profile in Firestore and cache
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestoreService.saveUserProfile(profile);
      _currentProfile = profile;
    } catch (e) {
      debugPrint('[ProfileService] Error updating profile: $e');
      _currentProfile = null;
      throw Exception("Failed to update profile: $e");
    }
  }

  /// Update profile (legacy compatibility method)
  Future<void> updateProfile(UserProfile updatedProfile) async {
    final profileWithTimestamp = updatedProfile.copyWith(
      updatedAt: DateTime.now(),
    );
    await updateUserProfile(profileWithTimestamp);
  }

  /// Update personal information
  Future<void> updatePersonalInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
  }) async {
    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          dateOfBirth: dateOfBirth,
          gender: gender,
          address: address,
          updatedAt: DateTime.now(),
        );
        await updateUserProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('Error updating personal info: $e');
      throw Exception('Failed to update personal information');
    }
  }

  /// Update emergency contact information
  Future<void> updateEmergencyContact({
    String? emergencyContact,
    String? emergencyPhone,
  }) async {
    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          emergencyContact: emergencyContact,
          emergencyPhone: emergencyPhone,
          updatedAt: DateTime.now(),
        );
        await updateUserProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('[ProfileService] Error updating emergency contact: $e');
      throw Exception('Failed to update emergency contact');
    }
  }

  /// Update medical information
  Future<void> updateMedicalInfo(MedicalInfo medicalInfo) async {
    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          medicalInfo: medicalInfo,
          updatedAt: DateTime.now(),
        );
        await updateUserProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('[ProfileService] Error updating medical info: $e');
      throw Exception('Failed to update medical information');
    }
  }

  /// Update app preferences
  Future<void> updateAppPreferences(AppPreferences preferences) async {
    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          preferences: preferences,
          updatedAt: DateTime.now(),
        );
        await updateUserProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('[ProfileService] Error updating preferences: $e');
      throw Exception('Failed to update preferences: $e');
    }
  }

  /// Update profile picture
  Future<void> updateProfilePicture(String imagePath) async {
    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          profileImagePath: imagePath,
          updatedAt: DateTime.now(),
        );
        await updateUserProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('[ProfileService] Error updating profile picture: $e');
      throw Exception('Failed to update profile picture');
    }
  }

  /// Delete user profile
  Future<void> deleteProfile() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      await _firestoreService.deleteUserProfile();
      await _authService.signOut();
      _currentProfile = null;
    } catch (e) {
      debugPrint('[ProfileService] Error deleting profile: $e');
      throw Exception('Failed to delete profile: $e');
    }
  }

  /// Clear cached profile (useful for logout or data refresh)
  void clearCache() {
    _currentProfile = null;
  }

  /// Export profile data as JSON
  Future<Map<String, dynamic>> exportProfileData() async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) return {};

      return {
        'profile': profile.toFirestore(),
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      debugPrint('[ProfileService] Error exporting profile data: $e');
      return {};
    }
  }

  /// Create backup data from Firebase
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final profile = await getCurrentProfile();
      final medications = await _firestoreService.getMedications();

      return {
        'profile': profile?.toFirestore(),
        'medications': medications,
        'backup_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return {};
    }
  }

  // Initialize with sample data if no profile exists
  Future<void> initializeSampleProfile() async {
    try {
      final existingProfile = await getCurrentProfile();
      if (existingProfile == null) {
        final sampleProfile = UserProfile(
          id: _generateId(),
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          phone: '+1 (555) 123-4567',
          dateOfBirth: DateTime(1990, 5, 15),
          gender: 'Male',
          address: '123 Main Street, City, State 12345',
          emergencyContact: 'Jane Doe',
          emergencyPhone: '+1 (555) 987-6543',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          medicalInfo: MedicalInfo(
            bloodType: 'O+',
            allergies: ['Penicillin', 'Shellfish'],
            medicalConditions: ['Hypertension'],
            doctorName: 'Dr. Sarah Smith',
            doctorPhone: '+1 (555) 456-7890',
            insuranceProvider: 'HealthCare Plus',
            insuranceNumber: 'HC123456789',
            height: 175.0,
            weight: 70.0,
            notes: 'Regular checkups every 6 months',
          ),
          preferences: AppPreferences(
            notificationsEnabled: true,
            reminderSounds: true,
            reminderInterval: 15,
            themeMode: ThemeMode.system,
            language: 'en',
            biometricAuth: false,
            autoBackup: true,
          ),
        );
        await updateUserProfile(sampleProfile);
      }
    } catch (e) {
      debugPrint('Error initializing sample profile: $e');
    }
  }

  // Health insights
  Future<Map<String, dynamic>> getHealthInsights() async {
    final profile = await getCurrentProfile();
    if (profile?.medicalInfo == null) return {};

    final medInfo = profile!.medicalInfo!;
    Map<String, dynamic> insights = {};

    // BMI insights
    if (medInfo.bmi != null) {
      insights['bmi'] = {
        'value': medInfo.bmi!.toStringAsFixed(1),
        'category': medInfo.bmiCategory,
        'isHealthy': medInfo.bmi! >= 18.5 && medInfo.bmi! < 25,
      };
    }

    // Health risks
    List<String> risks = [];
    if (medInfo.medicalConditions.isNotEmpty) {
      risks.addAll(medInfo.medicalConditions);
    }
    if (medInfo.allergies.isNotEmpty) {
      risks.add('${medInfo.allergies.length} known allergies');
    }
    insights['risks'] = risks;

    // Recommendations
    List<String> recommendations = [];
    if (medInfo.bmi != null && medInfo.bmi! >= 25) {
      recommendations.add('Consider weight management');
    }
    if (medInfo.medicalConditions.contains('Hypertension')) {
      recommendations.add('Monitor blood pressure regularly');
    }
    if (medInfo.allergies.isNotEmpty) {
      recommendations.add('Always carry allergy information');
    }
    insights['recommendations'] = recommendations;

    return insights;
  }

  // Profile statistics
  Future<Map<String, dynamic>> getProfileStats() async {
    final profile = await getCurrentProfile();
    if (profile == null) return {};

    final daysSinceCreated = DateTime.now()
        .difference(profile.createdAt)
        .inDays;
    final daysSinceLastUpdate = DateTime.now()
        .difference(profile.updatedAt)
        .inDays;

    return {
      'memberSince': daysSinceCreated,
      'lastUpdated': daysSinceLastUpdate,
      'completeness': ((await getProfileCompleteness()) * 100).round(),
      'age': profile.age,
    };
  }

  // Profile validation
  Future<bool> isProfileComplete() async {
    final profile = await getCurrentProfile();
    if (profile == null) return false;

    return profile.firstName.isNotEmpty &&
        profile.lastName.isNotEmpty &&
        profile.email.isNotEmpty &&
        profile.dateOfBirth != null;
  }

  Future<double> getProfileCompleteness() async {
    final profile = await getCurrentProfile();
    if (profile == null) return 0.0;

    int completed = 0;
    int total = 10;

    if (profile.firstName.isNotEmpty) completed++;
    if (profile.lastName.isNotEmpty) completed++;
    if (profile.email.isNotEmpty) completed++;
    if (profile.phone != null && profile.phone!.isNotEmpty) completed++;
    if (profile.dateOfBirth != null) completed++;
    if (profile.gender != null && profile.gender!.isNotEmpty) completed++;
    if (profile.address != null && profile.address!.isNotEmpty) completed++;
    if (profile.emergencyContact != null &&
        profile.emergencyContact!.isNotEmpty) {
      completed++;
    }
    if (profile.medicalInfo?.doctorName != null &&
        profile.medicalInfo!.doctorName!.isNotEmpty) {
      completed++;
    }
    if (profile.profileImagePath != null) completed++;

    return completed / total;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }
}
