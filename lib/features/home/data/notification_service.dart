import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/models.dart';
import '../../auth/data/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AuthService _authService = AuthService();

  // Get notifications from Firebase
  Future<List<NotificationItem>> getNotifications() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return [];

      final notificationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true);

      final snapshot = await notificationsRef
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          type: _parseNotificationType(data['type']),
          isRead: data['isRead'] ?? false,
          data: data['data'],
        );
      }).toList();
    } catch (e) {
      debugPrint('[NotificationService] Error getting notifications: $e');
      return [];
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return 0;

      final notificationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false);

      final snapshot = await notificationsRef
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('[NotificationService] Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final notificationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false);

      final snapshot = await notificationsRef
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Firestore operation timed out - check network connection',
          );
        },
      );
    } catch (e) {
      debugPrint('[NotificationService] Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );
    } catch (e) {
      debugPrint('[NotificationService] Error deleting notification: $e');
    }
  }

  // Create medication reminder notification
  Future<void> createMedicationReminder({
    required String medicationName,
    required String dose,
    required DateTime reminderTime,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: 'Medication Reminder',
      message: 'Time to take your $medicationName ($dose)',
      type: NotificationType.medicationReminder,
      data: {
        'medicationName': medicationName,
        'dose': dose,
        'reminderTime': reminderTime.toIso8601String(),
        ...?data,
      },
    );
  }

  // Create low stock alert
  Future<void> createLowStockAlert({
    required String medicationName,
    required int daysRemaining,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: 'Low Stock Alert',
      message:
          'Your $medicationName is running low ($daysRemaining days remaining)',
      type: NotificationType.lowStock,
      data: {
        'medicationName': medicationName,
        'daysRemaining': daysRemaining,
        ...?data,
      },
    );
  }

  // Create medication taken confirmation
  Future<void> createMedicationTaken({
    required String medicationName,
    required DateTime takenTime,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: 'Medication Taken',
      message: 'Great! You took your $medicationName',
      type: NotificationType.medicationTaken,
      data: {
        'medicationName': medicationName,
        'takenTime': takenTime.toIso8601String(),
        ...?data,
      },
    );
  }

  // Create missed dose alert
  Future<void> createMissedDose({
    required String medicationName,
    required DateTime missedTime,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: 'Missed Dose',
      message: 'You missed your $medicationName dose',
      type: NotificationType.missedDose,
      data: {
        'medicationName': medicationName,
        'missedTime': missedTime.toIso8601String(),
        ...?data,
      },
    );
  }

  // Create refill reminder
  Future<void> createRefillReminder({
    required String medicationName,
    required DateTime refillDate,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: 'Refill Reminder',
      message: 'Time to refill your $medicationName prescription',
      type: NotificationType.refillReminder,
      data: {
        'medicationName': medicationName,
        'refillDate': refillDate.toIso8601String(),
        ...?data,
      },
    );
  }

  // Create appointment reminder
  Future<void> createAppointmentReminder({
    required String doctorName,
    required String specialty,
    required DateTime appointmentDateTime,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: 'Appointment Reminder',
      message: 'You have an appointment with Dr. $doctorName ($specialty)',
      type: NotificationType.appointmentReminder,
      data: {
        'doctorName': doctorName,
        'specialty': specialty,
        'appointmentDateTime': appointmentDateTime.toIso8601String(),
        ...?data,
      },
    );
  }

  // Create water intake reminder
  Future<void> createWaterReminder({
    required int glasses,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: 'Hydration Reminder',
      message: 'Time to drink water! You\'ve had $glasses glass${glasses == 1 ? '' : 'es'} today.',
      type: NotificationType.waterReminder,
      data: {
        'glasses': glasses,
        ...?data,
      },
    );
  }

  // Create general notification
  Future<void> _createNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'type': type.toString(),
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': data ?? {},
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );
    } catch (e) {
      debugPrint('[NotificationService] Error creating notification: $e');
    }
  }

  // Initialize sample notifications if none exist
  Future<void> initializeSampleNotifications() async {
    try {
      final notifications = await getNotifications();
      if (notifications.isEmpty) {
        // Create sample notifications
        await createMedicationReminder(
          medicationName: 'Aspirin',
          dose: '100mg',
          reminderTime: DateTime.now().subtract(const Duration(minutes: 15)),
        );

        await createLowStockAlert(
          medicationName: 'Lisinopril',
          daysRemaining: 2,
        );

        await createMedicationTaken(
          medicationName: 'Metformin',
          takenTime: DateTime.now().subtract(const Duration(hours: 8)),
        );

        await createMissedDose(
          medicationName: 'Vitamin D',
          missedTime: DateTime.now().subtract(const Duration(days: 1)),
        );

        await createRefillReminder(
          medicationName: 'Omega-3',
          refillDate: DateTime.now().add(const Duration(days: 3)),
        );

        await createAppointmentReminder(
          doctorName: 'Dr. John Smith',
          specialty: 'Cardiology',
          appointmentDateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
        );

        await createWaterReminder(
          glasses: 4,
        );
      }
    } catch (e) {
      debugPrint('Error initializing sample notifications: $e');
    }
  }

  // Helper method to parse notification type from string
  NotificationType _parseNotificationType(dynamic typeString) {
    if (typeString == null) return NotificationType.medicationReminder;

    switch (typeString.toString()) {
      case 'NotificationType.medicationReminder':
        return NotificationType.medicationReminder;
      case 'NotificationType.lowStock':
        return NotificationType.lowStock;
      case 'NotificationType.medicationTaken':
        return NotificationType.medicationTaken;
      case 'NotificationType.missedDose':
        return NotificationType.missedDose;
      case 'NotificationType.refillReminder':
        return NotificationType.refillReminder;
      case 'NotificationType.appointmentReminder':
        return NotificationType.appointmentReminder;
      case 'NotificationType.waterReminder':
        return NotificationType.waterReminder;
      default:
        return NotificationType.medicationReminder;
    }
  }

  // Listen to real-time notification updates
  Stream<List<NotificationItem>> notificationsStream() {
    final userId = _authService.currentUserId;
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return NotificationItem(
              id: doc.id,
              title: data['title'] ?? '',
              message: data['message'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              type: _parseNotificationType(data['type']),
              isRead: data['isRead'] ?? false,
              data: data['data'],
            );
          }).toList();
        });
  }
}
