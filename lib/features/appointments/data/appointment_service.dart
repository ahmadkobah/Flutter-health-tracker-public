import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../auth/data/auth_service.dart';
import '../../home/data/notification_service.dart';
import '../../../core/models/models.dart';

/// Service for managing doctor appointments
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get current user ID - with validation
  String? get _currentUserId => _authService.currentUserId;

  // Check if user is authenticated
  bool get _isAuthenticated =>
      _authService.isSignedIn && _currentUserId != null;

  // Get user-specific appointments collection - SAFE version
  CollectionReference<Map<String, dynamic>> _getUserAppointmentsCollection() {
    final userId = _currentUserId;
    if (!_isAuthenticated || userId == null) {
      throw 'User not authenticated or user ID is null';
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('appointments');
  }

  // Create a new appointment
  Future<String> createAppointment(DoctorAppointment appointment) async {
    try {
      final appointmentsCollection = _getUserAppointmentsCollection();
      final docRef = await appointmentsCollection
          .add(appointment.toFirestore())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );

      // Update the appointment with the generated ID
      await docRef.update({'id': docRef.id}).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Firestore operation timed out - check network connection',
          );
        },
      );

      // Create appointment reminder notification
      final appointmentDateTime = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
        appointment.appointmentTime.hour,
        appointment.appointmentTime.minute,
      );
      
      final notificationService = NotificationService();
      await notificationService.createAppointmentReminder(
        doctorName: appointment.doctorName,
        specialty: appointment.specialty,
        appointmentDateTime: appointmentDateTime,
      );

      debugPrint(
        'Appointment created successfully: ${docRef.id} for user: $_currentUserId',
      );
      return docRef.id;
    } catch (e) {
      debugPrint('[AppointmentService] Error creating appointment: $e');
      rethrow;
    }
  }

  // Get all appointments for the current user
  Future<List<DoctorAppointment>> getUserAppointments() async {
    try {
      if (!_isAuthenticated) {
        debugPrint('User not authenticated, returning empty appointments list');
        return [];
      }

      final appointmentsCollection = _getUserAppointmentsCollection();
      final querySnapshot = await appointmentsCollection
          .orderBy('appointmentDate', descending: false)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => DoctorAppointment.fromFirestore(doc.data()))
          .toList();

      debugPrint(
        'Retrieved ${appointments.length} appointments for user: $_currentUserId',
      );
      return appointments;
    } catch (e) {
      debugPrint('Error getting appointments: $e');
      return [];
    }
  }

  // Get upcoming appointments (next 30 days)
  Future<List<DoctorAppointment>> getUpcomingAppointments() async {
    try {
      if (!_isAuthenticated) {
        debugPrint(
          'User not authenticated, returning empty upcoming appointments list',
        );
        return [];
      }

      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));

      final appointmentsCollection = _getUserAppointmentsCollection();
      final querySnapshot = await appointmentsCollection
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('appointmentDate', descending: false)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => DoctorAppointment.fromFirestore(doc.data()))
          .toList();

      debugPrint(
        'Retrieved ${appointments.length} upcoming appointments for user: $_currentUserId',
      );
      return appointments;
    } catch (e) {
      debugPrint('Error getting upcoming appointments: $e');
      return [];
    }
  }

  // Update an appointment
  Future<void> updateAppointment(DoctorAppointment appointment) async {
    try {
      final appointmentsCollection = _getUserAppointmentsCollection();
      await appointmentsCollection
          .doc(appointment.id)
          .update(
            appointment.copyWith(updatedAt: DateTime.now()).toFirestore(),
          );

      // Create updated appointment reminder notification
      final appointmentDateTime = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
        appointment.appointmentTime.hour,
        appointment.appointmentTime.minute,
      );
      
      final notificationService = NotificationService();
      await notificationService.createAppointmentReminder(
        doctorName: appointment.doctorName,
        specialty: appointment.specialty,
        appointmentDateTime: appointmentDateTime,
      );

      debugPrint(
        'Appointment updated successfully: ${appointment.id} for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      rethrow;
    }
  }

  // Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      final appointmentsCollection = _getUserAppointmentsCollection();
      await appointmentsCollection.doc(appointmentId).delete();

      // Note: Firestore notifications for this appointment will remain in user's notification history
      // They won't show as "upcoming" since the appointment is deleted
      // To completely remove, you would need to delete the notification from Firestore
      // For now, we just log the deletion
      debugPrint(
        'Appointment deleted successfully: $appointmentId for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      rethrow;
    }
  }

  // Get appointment by ID
  Future<DoctorAppointment?> getAppointmentById(String appointmentId) async {
    try {
      if (!_isAuthenticated) {
        debugPrint('User not authenticated');
        return null;
      }

      final appointmentsCollection = _getUserAppointmentsCollection();
      final doc = await appointmentsCollection.doc(appointmentId).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final appointment = DoctorAppointment.fromFirestore(data);
          debugPrint(
            'Retrieved appointment: $appointmentId for user: $_currentUserId',
          );
          return appointment;
        }
      }
      debugPrint('Appointment not found: $appointmentId');
      return null;
    } catch (e) {
      debugPrint('Error getting appointment by ID: $e');
      return null;
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    try {
      final appointmentsCollection = _getUserAppointmentsCollection();
      await appointmentsCollection.doc(appointmentId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Appointment status updated successfully: $appointmentId -> $status for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      rethrow;
    }
  }

  // Search appointments by doctor name or specialty
  Future<List<DoctorAppointment>> searchAppointments(String query) async {
    try {
      if (!_isAuthenticated) {
        debugPrint('User not authenticated, returning empty search results');
        return [];
      }

      final appointmentsCollection = _getUserAppointmentsCollection();

      // Get all appointments and filter locally (Firestore doesn't support complex text search)
      final querySnapshot = await appointmentsCollection
          .orderBy('appointmentDate', descending: false)
          .get();

      final allAppointments = querySnapshot.docs
          .map((doc) => DoctorAppointment.fromFirestore(doc.data()))
          .toList();

      // Filter by doctor name or specialty
      final lowercaseQuery = query.toLowerCase();
      final filtered = allAppointments.where((appointment) {
        return appointment.doctorName.toLowerCase().contains(lowercaseQuery) ||
            appointment.specialty.toLowerCase().contains(lowercaseQuery);
      }).toList();

      debugPrint(
        'Search found ${filtered.length} appointments for query "$query" for user: $_currentUserId',
      );
      return filtered;
    } catch (e) {
      debugPrint('Error searching appointments: $e');
      return [];
    }
  }

  // Get appointments for a specific date
  Future<List<DoctorAppointment>> getAppointmentsForDate(DateTime date) async {
    try {
      if (!_isAuthenticated) {
        debugPrint(
          'User not authenticated, returning empty appointments for date',
        );
        return [];
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final appointmentsCollection = _getUserAppointmentsCollection();
      final querySnapshot = await appointmentsCollection
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .orderBy('appointmentDate', descending: false)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => DoctorAppointment.fromFirestore(doc.data()))
          .toList();

      debugPrint(
        'Retrieved ${appointments.length} appointments for date ${date.toIso8601String()} for user: $_currentUserId',
      );
      return appointments;
    } catch (e) {
      debugPrint('Error getting appointments for date: $e');
      return [];
    }
  }

  // Real-time stream of appointments for the current user
  Stream<List<DoctorAppointment>> getAppointmentsStream() {
    try {
      if (!_isAuthenticated) {
        debugPrint('User not authenticated, returning empty stream');
        return Stream.value([]);
      }

      return _getUserAppointmentsCollection()
          .orderBy('appointmentDate', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => DoctorAppointment.fromFirestore(doc.data()))
                .toList(),
          );
    } catch (e) {
      debugPrint('Error creating appointments stream: $e');
      return Stream.value([]);
    }
  }

  // Initialize sample data for testing
  Future<void> initializeSampleData() async {
    try {
      if (!_isAuthenticated) {
        debugPrint('User not authenticated, cannot initialize sample data');
        return;
      }

      final appointments = await getUserAppointments();
      if (appointments.isNotEmpty) {
        debugPrint(
          'Sample appointment data already exists for user: $_currentUserId',
        );
        return;
      }

      final sampleAppointments = [
        DoctorAppointment(
          id: '',
          doctorName: 'Dr. Sarah Johnson',
          specialty: 'Cardiologist',
          appointmentDate: DateTime.now().add(const Duration(days: 7)),
          appointmentTime: const TimeOfDay(hour: 10, minute: 30),
          location: 'Heart Care Center',
          address: '123 Medical Plaza, Suite 200',
          phoneNumber: '+1 (555) 123-4567',
          notes: 'Follow-up for blood pressure monitoring',
          status: AppointmentStatus.scheduled,
          reminderMinutesBefore: 60,
          createdAt: DateTime.now(),
        ),
        DoctorAppointment(
          id: '',
          doctorName: 'Dr. Michael Chen',
          specialty: 'General Practice',
          appointmentDate: DateTime.now().add(const Duration(days: 14)),
          appointmentTime: const TimeOfDay(hour: 14, minute: 0),
          location: 'Family Health Clinic',
          address: '456 Main Street',
          phoneNumber: '+1 (555) 987-6543',
          notes: 'Annual physical exam',
          status: AppointmentStatus.scheduled,
          reminderMinutesBefore: 30,
          createdAt: DateTime.now(),
        ),
        DoctorAppointment(
          id: '',
          doctorName: 'Dr. Emily Rodriguez',
          specialty: 'Dermatologist',
          appointmentDate: DateTime.now().add(const Duration(days: 21)),
          appointmentTime: const TimeOfDay(hour: 9, minute: 15),
          location: 'Skin Health Institute',
          address: '789 Wellness Boulevard',
          phoneNumber: '+1 (555) 456-7890',
          notes: 'Skin cancer screening',
          status: AppointmentStatus.confirmed,
          reminderMinutesBefore: 45,
          createdAt: DateTime.now(),
        ),
      ];

      for (final appointment in sampleAppointments) {
        await createAppointment(appointment);
      }

      debugPrint(
        'Sample appointment data initialized successfully for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('Error initializing sample appointment data: $e');
    }
  }
}
