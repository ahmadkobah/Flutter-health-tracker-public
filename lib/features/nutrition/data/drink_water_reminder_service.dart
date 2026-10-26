import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DrinkWaterReminderService {
  final String userId;
  DrinkWaterReminderService(this.userId);

  // Use user-specific document path for proper isolation
  DocumentReference<Map<String, dynamic>> get _userDoc => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('water_settings')
      .doc('current_settings');

  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final doc = await _userDoc.get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting water settings: $e');
      return null;
    }
  }

  Future<void> saveSettings({
    required int glasses,
    required int reminderInterval,
    required bool notificationsEnabled,
    required DateTime lastResetDate,
  }) async {
    try {
      await _userDoc.set({
        'userId': userId, // Explicit user association
        'water_glasses': glasses,
        'water_reminder_interval': reminderInterval,
        'water_notifications_enabled': notificationsEnabled,
        'water_last_reset': lastResetDate.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving water settings: $e');
      rethrow;
    }
  }

  Future<void> updateGlasses(int glasses) async {
    try {
      await _userDoc.update({
        'water_glasses': glasses,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating glasses: $e');
      rethrow;
    }
  }

  Future<void> resetGlasses(DateTime resetDate) async {
    try {
      await _userDoc.update({
        'water_glasses': 0,
        'water_last_reset': resetDate.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error resetting glasses: $e');
      rethrow;
    }
  }
}
