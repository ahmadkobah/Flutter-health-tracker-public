import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../../features/auth/data/auth_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUserId;

  // Check if user is authenticated
  bool get _isAuthenticated => _auth.isSignedIn;

  // ==================== USER PROFILE OPERATIONS ====================

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    if (!_isAuthenticated || _currentUserId == null) {
      debugPrint('getUserProfile: user not authenticated or no userId');
      return null;
    }

    try {
      debugPrint('getUserProfile: fetching profile for user $_currentUserId');
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint(
                'getUserProfile: Firestore get operation timed out after 10 seconds',
              );
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );

      if (doc.exists) {
        final profile = UserProfile.fromFirestore(doc.data()!);
        debugPrint(
          'Loaded user profile from Firestore: name=${profile.firstName} ${profile.lastName}, email=${profile.email}',
        );
        return profile;
      }
      debugPrint('No user profile found in Firestore for user $_currentUserId');
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      throw 'Failed to load user profile: $e';
    }
  }

  // Create or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      throw 'Failed to save user profile';
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile() async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      debugPrint(
        'deleteUserProfile: Deleting profile for user $_currentUserId',
      );

      // Delete the main user document
      await _firestore.collection('users').doc(_currentUserId).delete();

      debugPrint('deleteUserProfile: Profile deleted successfully');
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      throw 'Failed to delete user profile: $e';
    }
  }

  // Listen to user profile changes
  Stream<UserProfile?> getUserProfileStream() {
    if (!_isAuthenticated || _currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(_currentUserId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!);
      }
      return null;
    });
  }

  // ==================== MEDICATION OPERATIONS ====================

  // Get all user medications
  Future<List<Medication>> getMedications() async {
    if (!_isAuthenticated || _currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medications')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Medication.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting medications: $e');
      throw 'Failed to load medications';
    }
  }

  // Add new medication
  Future<String> addMedication(Medication medication) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      debugPrint('addMedication: currentUserId=$_currentUserId');
      debugPrint('addMedication: isAuthenticated=$_isAuthenticated');
      debugPrint('addMedication: medication data=${medication.toFirestore()}');

      // Add timeout to prevent hanging
      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medications')
          .add(medication.toFirestore())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint(
                'addMedication: Firestore add operation timed out after 10 seconds',
              );
              throw Exception(
                'Firestore operation timed out - check network connection and Firebase configuration',
              );
            },
          );

      debugPrint('addMedication: document added, updating with ID...');
      // Update the medication with the generated ID
      await docRef.update({'id': docRef.id});
      debugPrint('addMedication: medication added with id=${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      debugPrint('Error adding medication: $e');
      debugPrint('Stack trace: $stack');
      throw 'Failed to add medication: $e';
    }
  }

  // Update medication
  Future<void> updateMedication(
    String medicationId,
    Medication medication,
  ) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medications')
          .doc(medicationId)
          .update(medication.toFirestore());
    } catch (e) {
      debugPrint('Error updating medication: $e');
      throw 'Failed to update medication';
    }
  }

  // Delete medication
  Future<void> deleteMedication(String medicationId) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medications')
          .doc(medicationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      throw 'Failed to delete medication';
    }
  }

  // Get single medication
  Future<Medication?> getMedication(String medicationId) async {
    if (!_isAuthenticated || _currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medications')
          .doc(medicationId)
          .get();

      if (doc.exists) {
        return Medication.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting medication: $e');
      throw 'Failed to load medication';
    }
  }

  // Listen to medications changes
  Stream<List<Medication>> getMedicationsStream() {
    if (!_isAuthenticated || _currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('medications')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Medication.fromFirestore(doc.data()))
              .toList(),
        );
  }

  // Listen to appointments changes for the current user
  Stream<List<DoctorAppointment>> getAppointmentsStream() {
    if (!_isAuthenticated || _currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('appointments')
        .orderBy('appointmentDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DoctorAppointment.fromFirestore(doc.data()))
              .toList(),
        );
  }

  // Listen to nutrition schedule changes for the current user
  // Nutrition schedules are stored under root collection 'nutrition_schedules' with a document per user
  Stream<Map<String, dynamic>?> getNutritionScheduleStream() {
    if (!_isAuthenticated || _currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('nutrition_schedules')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) => doc.exists ? (doc.data() as Map<String, dynamic>) : null);
  }

  // ==================== MEDICATION LOG OPERATIONS ====================

  // Add medication log entry
  Future<void> logMedicationTaken({
    required String medicationId,
    required String medicationName,
    required DateTime scheduledTime,
    required DateTime takenTime,
    required String status, // 'taken', 'missed', 'skipped'
    String? notes,
    List<String>? sideEffects,
  }) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      final logData = {
        'medicationId': medicationId,
        'medicationName': medicationName,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'takenTime': Timestamp.fromDate(takenTime),
        'status': status,
        'notes': notes,
        'sideEffects': sideEffects ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medicationLogs')
          .add(logData);
    } catch (e) {
      debugPrint('Error logging medication: $e');
      throw 'Failed to log medication';
    }
  }

  // Get medication logs for date range
  Future<List<Map<String, dynamic>>> getMedicationLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? medicationId,
  }) async {
    if (!_isAuthenticated || _currentUserId == null) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medicationLogs');

      if (startDate != null) {
        query = query.where(
          'scheduledTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'scheduledTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      if (medicationId != null) {
        query = query.where('medicationId', isEqualTo: medicationId);
      }

      query = query.orderBy('scheduledTime', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting medication logs: $e');
      throw 'Failed to load medication logs';
    }
  }

  // ==================== NOTIFICATION OPERATIONS ====================

  // Add notification
  Future<void> addNotification(NotificationItem notification) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      debugPrint('Error adding notification: $e');
      throw 'Failed to add notification';
    }
  }

  // Get notifications
  Future<List<NotificationItem>> getNotifications({int? limit}) async {
    if (!_isAuthenticated || _currentUserId == null) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => NotificationItem.fromFirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      throw 'Failed to load notifications';
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      throw 'Failed to update notification';
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      throw 'Failed to update notifications';
    }
  }

  // Listen to notifications
  Stream<List<NotificationItem>> getNotificationsStream({int? limit}) {
    if (!_isAuthenticated || _currentUserId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => NotificationItem.fromFirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  // ==================== UTILITY OPERATIONS ====================

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    if (!_isAuthenticated || _currentUserId == null) return {};

    try {
      // Get medications count
      final medicationsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medications')
          .get();

      // Get today's logs
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('medicationLogs')
          .where(
            'scheduledTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final takenCount = logsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'taken')
          .length;

      return {
        'totalMedications': medicationsSnapshot.docs.length,
        'todayTaken': takenCount,
        'todayTotal': logsSnapshot.docs.length,
        'adherenceRate': logsSnapshot.docs.isNotEmpty
            ? (takenCount / logsSnapshot.docs.length * 100).round()
            : 0,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {};
    }
  }

  // Batch operations for better performance
  Future<void> batchUpdateMedications(List<Medication> medications) async {
    if (!_isAuthenticated || _currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      final batch = _firestore.batch();

      for (final medication in medications) {
        final docRef = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('medications')
            .doc(medication.id);

        batch.set(docRef, medication.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error batch updating medications: $e');
      throw 'Failed to update medications';
    }
  }

  // Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      _firestore.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      debugPrint('Error enabling offline persistence: $e');
    }
  }
}
