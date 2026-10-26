import '../../auth/data/auth_service.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../core/models/models.dart';
import '../../../core/services/firestore_service.dart';
import '../../home/data/notification_service.dart';

/// Service for managing medications and dosage tracking
class MedicationService {
  static final MedicationService _instance = MedicationService._internal();
  factory MedicationService() => _instance;
  MedicationService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Cache for medications to improve performance
  List<Medication> _cachedMedications = [];
  List<MedicationLog> _cachedMedicationLogs = [];
  bool _isInitialized = false;

  // Initialize service and load cached data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      await _initializeNotifications();
      await _loadMedications();
      await _loadMedicationLogs();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing MedicationService: $e');
    }
  }

  // Load medications from Firestore
  Future<void> _loadMedications() async {
    try {
      _cachedMedications = await _firestoreService.getMedications();
      debugPrint(
        'Loaded ${_cachedMedications.length} medications from Firestore:',
      );
      for (final med in _cachedMedications) {
        debugPrint('Medication: ${med.name}');
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
      _cachedMedications = [];
    }
  }

  // Load medication logs from Firestore
  Future<void> _loadMedicationLogs() async {
    try {
      final logs = await _firestoreService.getMedicationLogs();
      _cachedMedicationLogs = logs
          .map(
            (logData) => MedicationLog(
              id: logData['id'] ?? '',
              medicationId: logData['medicationId'] ?? '',
              takenAt:
                  (logData['takenTime'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              notes: logData['notes'],
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading medication logs: $e');
      _cachedMedicationLogs = [];
    }
  }

  // Initialize with sample data (disabled to prevent hanging)
  Future<void> initializeSampleData() async {
    await initialize();

    debugPrint('Sample medication data creation is disabled');
    return; // Exit early without creating sample data
  }

  // CRUD Operations
  Future<List<Medication>> getAllMedications() async {
    await initialize();
    return List.unmodifiable(_cachedMedications);
  }

  Future<Medication?> getMedicationById(String id) async {
    await initialize();
    try {
      return _cachedMedications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Medication>> getMedicationsBySlot(TimeOfDaySlot slot) async {
    await initialize();
    return _cachedMedications.where((med) => med.slot == slot).toList();
  }

  Future<List<Medication>> getActiveMedications() async {
    await initialize();
    final now = DateTime.now();
    return _cachedMedications.where((med) {
      if (med.endDate != null && med.endDate!.isBefore(now)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<List<Medication>> searchMedications(String query) async {
    await initialize();
    final lowercaseQuery = query.toLowerCase();
    return _cachedMedications.where((med) {
      return med.name.toLowerCase().contains(lowercaseQuery) ||
          med.description.toLowerCase().contains(lowercaseQuery) ||
          (med.prescriber?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  Future<void> addMedication(Medication medication) async {
    debugPrint(
      'addMedication: Attempting to add medication: ${medication.name}',
    );
    final authService = AuthService();
    debugPrint(
      'Auth state before Firestore write: userId=${authService.currentUserId}, isSignedIn=${authService.isSignedIn}',
    );
    try {
      final medicationId = await _firestoreService.addMedication(medication);
      debugPrint('addMedication: Medication added with ID: $medicationId');
      final updatedMedication = medication.copyWith(id: medicationId);
      _cachedMedications.add(updatedMedication);
      
      // Schedule medication reminders
      await _scheduleMedicationReminders(updatedMedication);
    } catch (e) {
      debugPrint('addMedication: Failed to add medication: $e');
      throw 'Failed to add medication: $e';
    }
  }

  Future<void> updateMedication(Medication updatedMedication) async {
    debugPrint(
      'updateMedication: Attempting to update medication: ${updatedMedication.id}',
    );
    try {
      await _firestoreService.updateMedication(
        updatedMedication.id,
        updatedMedication,
      );
      debugPrint(
        'updateMedication: Medication updated: ${updatedMedication.id}',
      );
      final index = _cachedMedications.indexWhere(
        (med) => med.id == updatedMedication.id,
      );
      if (index != -1) {
        _cachedMedications[index] = updatedMedication;
      }
      
      // Reschedule medication reminders
      await _cancelMedicationReminders(updatedMedication.id);
      await _scheduleMedicationReminders(updatedMedication);
    } catch (e) {
      debugPrint('updateMedication: Failed to update medication: $e');
      throw 'Failed to update medication: $e';
    }
  }

  Future<void> deleteMedication(String id) async {
    debugPrint('deleteMedication: Attempting to delete medication: $id');
    try {
      await _firestoreService.deleteMedication(id);
      debugPrint('deleteMedication: Medication deleted: $id');
      _cachedMedications.removeWhere((med) => med.id == id);
      // Also remove related logs
      _cachedMedicationLogs.removeWhere((log) => log.medicationId == id);
      
      // Cancel medication reminders
      await _cancelMedicationReminders(id);
    } catch (e) {
      debugPrint('deleteMedication: Failed to delete medication: $e');
      throw 'Failed to delete medication: $e';
    }
  }

  // Medication tracking
  Future<void> markMedicationTaken(
    String medicationId, {
    DateTime? takenAt,
    String? notes,
  }) async {
    final medication = await getMedicationById(medicationId);
    if (medication != null) {
      final updatedMedication = medication.copyWith(
        taken: true,
        lastTaken: takenAt ?? DateTime.now(),
      );
      await updateMedication(updatedMedication);

      // Add to log using Firestore service
      try {
        await _firestoreService.logMedicationTaken(
          medicationId: medicationId,
          medicationName: medication.name,
          scheduledTime: takenAt ?? DateTime.now(),
          takenTime: takenAt ?? DateTime.now(),
          status: 'taken',
          notes: notes,
        );

        // Update cache
        final log = MedicationLog(
          id: _generateId(),
          medicationId: medicationId,
          takenAt: takenAt ?? DateTime.now(),
          notes: notes,
        );
        _cachedMedicationLogs.add(log);
        
        // Create medication taken notification
        final notificationService = NotificationService();
        await notificationService.createMedicationTaken(
          medicationName: medication.name,
          takenTime: takenAt ?? DateTime.now(),
        );
      } catch (e) {
        debugPrint('Error adding medication log: $e');
      }
    }
  }

  Future<void> markMedicationNotTaken(String medicationId) async {
    final medication = await getMedicationById(medicationId);
    if (medication != null) {
      final updatedMedication = medication.copyWith(taken: false);
      await updateMedication(updatedMedication);
    }
  }

  // Get today's medications
  Future<List<Medication>> getTodaysMedications() async {
    await initialize();
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);

    return _cachedMedications.where((med) {
      if (med.slot == TimeOfDaySlot.asNeeded) return false;
      return med.schedule.contains(dayName) || med.schedule.contains('Daily');
    }).toList();
  }

  // Get medications due now
  Future<List<Medication>> getMedicationsDueNow() async {
    final now = DateTime.now();
    final currentHour = now.hour;
    final todaysMeds = await getTodaysMedications();

    return todaysMeds.where((med) {
      switch (med.slot) {
        case TimeOfDaySlot.morning:
          return currentHour >= 6 && currentHour < 12;
        case TimeOfDaySlot.afternoon:
          return currentHour >= 12 && currentHour < 17;
        case TimeOfDaySlot.evening:
          return currentHour >= 17 && currentHour < 21;
        case TimeOfDaySlot.night:
          return currentHour >= 21 || currentHour < 6;
        default:
          return false;
      }
    }).toList();
  }

  // Statistics
  Future<Map<String, int>> getTodaysProgress() async {
    final todaysMeds = await getTodaysMedications();
    final takenCount = todaysMeds.where((med) => med.taken).length;
    return {
      'total': todaysMeds.length,
      'taken': takenCount,
      'remaining': todaysMeds.length - takenCount,
    };
  }

  // Get medication history
  Future<List<MedicationLog>> getMedicationHistory(String medicationId) async {
    await initialize();
    return _cachedMedicationLogs
        .where((log) => log.medicationId == medicationId)
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  Future<List<MedicationLog>> getRecentMedicationLogs({int days = 7}) async {
    await initialize();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _cachedMedicationLogs
        .where((log) => log.takenAt.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  // Adherence calculation
  Future<double> getMedicationAdherence(
    String medicationId, {
    int days = 30,
  }) async {
    final medication = await getMedicationById(medicationId);
    if (medication == null) return 0.0;

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    // Calculate expected doses
    int expectedDoses = 0;
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      if (medication.schedule.contains(dayName)) {
        expectedDoses++;
      }
    }

    // Calculate actual doses taken
    await initialize();
    final logsInPeriod = _cachedMedicationLogs
        .where(
          (log) =>
              log.medicationId == medicationId &&
              log.takenAt.isAfter(startDate) &&
              log.takenAt.isBefore(endDate),
        )
        .length;

    return expectedDoses > 0 ? logsInPeriod / expectedDoses : 0.0;
  }

  // Utility methods
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  // Reset daily tracking (called at start of each day)
  Future<void> resetDailyTracking() async {
    await initialize();
    for (int i = 0; i < _cachedMedications.length; i++) {
      _cachedMedications[i] = _cachedMedications[i].copyWith(taken: false);
      await updateMedication(_cachedMedications[i]);
    }
  }

  // Get medication count by type
  Future<Map<MedicationType, int>> getMedicationCountByType() async {
    await initialize();
    final counts = <MedicationType, int>{};
    for (final type in MedicationType.values) {
      counts[type] = _cachedMedications.where((med) => med.type == type).length;
    }
    return counts;
  }

  // Get upcoming medications (next 4 hours)
  Future<List<Medication>> getUpcomingMedications() async {
    final now = DateTime.now();
    final currentHour = now.hour;
    final todaysMeds = await getTodaysMedications();

    return todaysMeds.where((med) {
      if (med.taken) return false;

      switch (med.slot) {
        case TimeOfDaySlot.morning:
          return currentHour < 12;
        case TimeOfDaySlot.afternoon:
          return currentHour < 17;
        case TimeOfDaySlot.evening:
          return currentHour < 21;
        case TimeOfDaySlot.night:
          return currentHour >= 21 || currentHour < 6;
        default:
          return false;
      }
    }).toList();
  }

  // Stream methods for real-time updates
  Stream<List<Medication>> getMedicationsStream() {
    return _firestoreService.getMedicationsStream();
  }

  // Initialize local notifications for medication reminders
  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _notificationsPlugin.initialize(settings);
      debugPrint('[MedicationService] Notifications initialized');
    } catch (e) {
      debugPrint('[MedicationService] Error initializing notifications: $e');
    }
  }

  // Schedule medication reminders
  Future<void> _scheduleMedicationReminders(Medication medication) async {
    try {
      if (medication.reminderMinutesBefore == null ||
          medication.reminderMinutesBefore == 0) {
        return;
      }

      final today = DateTime.now();
      final medicationSchedule = medication.schedule;

      // Get the slot time
      final slotTime = _getSlotTime(medication.slot);
      final reminderTime = slotTime.subtract(
        Duration(minutes: medication.reminderMinutesBefore ?? 15),
      );

      // Schedule reminders for the next 30 days for each scheduled day
      for (int i = 0; i < 30; i++) {
        final date = today.add(Duration(days: i));
        // Check if this day is in the schedule
        if (medicationSchedule.contains(_getDayName(date.weekday))) {
          final scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            reminderTime.hour,
            reminderTime.minute,
          );

          // Only schedule if it's in the future
          if (scheduledDateTime.isAfter(DateTime.now())) {
            final notificationId = medication.id.hashCode + i;
            final tzScheduledDate = tz.TZDateTime.from(
              scheduledDateTime,
              tz.local,
            );

            await _notificationsPlugin.zonedSchedule(
              notificationId,
              'Time for your medication',
              'It\'s time to take ${medication.name} (${medication.dose})',
              tzScheduledDate,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'medication_channel',
                  'Medication Reminders',
                  channelDescription: 'Reminders for medication doses',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  sound: 'default.aiff',
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              payload: 'medication_reminder_${medication.id}',
            );

            debugPrint(
              '[MedicationService] Scheduled reminder for ${medication.name} on $date at ${reminderTime.hour}:${reminderTime.minute}',
            );
          }
        }
      }

      // Also create an in-app notification
      final notificationService = NotificationService();
      await notificationService.createMedicationReminder(
        medicationName: medication.name,
        dose: medication.dose,
        reminderTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[MedicationService] Error scheduling medication reminders: $e');
    }
  }

  // Cancel medication reminders
  Future<void> _cancelMedicationReminders(String medicationId) async {
    try {
      // Cancel up to 30 notifications for this medication
      for (int i = 0; i < 30; i++) {
        final notificationId = medicationId.hashCode + i;
        await _notificationsPlugin.cancel(notificationId);
      }
      debugPrint('[MedicationService] Cancelled reminders for $medicationId');
    } catch (e) {
      debugPrint('[MedicationService] Error cancelling reminders: $e');
    }
  }

  // Get slot time based on TimeOfDaySlot
  DateTime _getSlotTime(TimeOfDaySlot slot) {
    final now = DateTime.now();
    switch (slot) {
      case TimeOfDaySlot.morning:
        return DateTime(now.year, now.month, now.day, 8, 0);
      case TimeOfDaySlot.afternoon:
        return DateTime(now.year, now.month, now.day, 13, 0);
      case TimeOfDaySlot.evening:
        return DateTime(now.year, now.month, now.day, 18, 0);
      case TimeOfDaySlot.night:
        return DateTime(now.year, now.month, now.day, 21, 0);
      default:
        return DateTime(now.year, now.month, now.day, 12, 0);
    }
  }

  // Get day name from weekday number (already defined above, removing duplicate)
}
