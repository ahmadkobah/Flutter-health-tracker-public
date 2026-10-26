import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============= DATA MODELS =============

/// Represents a medication entry
class Medication {
  final String id;
  final String name;
  final String dose;
  final String description;
  final TimeOfDaySlot slot;
  final List<String> schedule; // Days of the week or specific times
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final String? prescriber;
  final MedicationType type;
  final String? sideEffects;
  final String? instructions;
  bool taken;
  final DateTime? lastTaken;
  final int? reminderMinutesBefore;

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.description,
    required this.slot,
    required this.schedule,
    required this.startDate,
    required this.type,
    this.endDate,
    this.notes,
    this.prescriber,
    this.sideEffects,
    this.instructions,
    this.taken = false,
    this.lastTaken,
    this.reminderMinutesBefore,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'description': description,
      'slot': slot.toString(),
      'schedule': schedule,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'prescriber': prescriber,
      'type': type.toString(),
      'sideEffects': sideEffects,
      'instructions': instructions,
      'taken': taken,
      'lastTaken': lastTaken?.toIso8601String(),
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  // Create from Map
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dose: map['dose'],
      description: map['description'],
      slot: TimeOfDaySlot.values.firstWhere(
        (e) => e.toString() == map['slot'],
        orElse: () => TimeOfDaySlot.morning,
      ),
      schedule: List<String>.from(map['schedule']),
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      notes: map['notes'],
      prescriber: map['prescriber'],
      type: MedicationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MedicationType.tablet,
      ),
      sideEffects: map['sideEffects'],
      instructions: map['instructions'],
      taken: map['taken'] ?? false,
      lastTaken: map['lastTaken'] != null
          ? DateTime.parse(map['lastTaken'])
          : null,
      reminderMinutesBefore: map['reminderMinutesBefore'],
    );
  }

  // Copy with method for updates
  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    String? description,
    TimeOfDaySlot? slot,
    List<String>? schedule,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    String? prescriber,
    MedicationType? type,
    String? sideEffects,
    String? instructions,
    bool? taken,
    DateTime? lastTaken,
    int? reminderMinutesBefore,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      description: description ?? this.description,
      slot: slot ?? this.slot,
      schedule: schedule ?? this.schedule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      prescriber: prescriber ?? this.prescriber,
      type: type ?? this.type,
      sideEffects: sideEffects ?? this.sideEffects,
      instructions: instructions ?? this.instructions,
      taken: taken ?? this.taken,
      lastTaken: lastTaken ?? this.lastTaken,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'description': description,
      'slot': slot.toString(),
      'schedule': schedule,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'notes': notes,
      'prescriber': prescriber,
      'type': type.toString(),
      'sideEffects': sideEffects,
      'instructions': instructions,
      'taken': taken,
      'lastTaken': lastTaken != null ? Timestamp.fromDate(lastTaken!) : null,
      'reminderMinutesBefore': reminderMinutesBefore,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory Medication.fromFirestore(Map<String, dynamic> data) {
    return Medication(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      dose: data['dose'] ?? '',
      description: data['description'] ?? '',
      slot: TimeOfDaySlot.values.firstWhere(
        (e) => e.toString() == data['slot'],
        orElse: () => TimeOfDaySlot.morning,
      ),
      schedule: List<String>.from(data['schedule'] ?? []),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      prescriber: data['prescriber'],
      type: MedicationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => MedicationType.tablet,
      ),
      sideEffects: data['sideEffects'],
      instructions: data['instructions'],
      taken: data['taken'] ?? false,
      lastTaken: (data['lastTaken'] as Timestamp?)?.toDate(),
      reminderMinutesBefore: data['reminderMinutesBefore'],
    );
  }
}

enum TimeOfDaySlot {
  morning,
  afternoon,
  evening,
  night,
  asNeeded,
  beforeMeals,
  afterMeals,
  withMeals,
}

enum MedicationType {
  tablet,
  capsule,
  liquid,
  injection,
  cream,
  drops,
  inhaler,
  patch,
  spray,
  other,
}

// Medication Log for tracking history
class MedicationLog {
  final String id;
  final String medicationId;
  final DateTime takenAt;
  final String? notes;
  final double? actualDose;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.takenAt,
    this.notes,
    this.actualDose,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'takenAt': takenAt.toIso8601String(),
      'notes': notes,
      'actualDose': actualDose,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'],
      medicationId: map['medicationId'],
      takenAt: DateTime.parse(map['takenAt']),
      notes: map['notes'],
      actualDose: map['actualDose']?.toDouble(),
    );
  }
}

// Medication Reminder
class MedicationReminder {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  final bool isCompleted;
  final DateTime? completedAt;

  MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    return MedicationReminder(
      id: map['id'],
      medicationId: map['medicationId'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }
}

// User Profile Models
class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profileImagePath;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final MedicalInfo? medicalInfo;
  final AppPreferences? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.profileImagePath,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    this.medicalInfo,
    this.preferences,
  });

  String get fullName => '$firstName $lastName';

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'profileImagePath': profileImagePath,
      'address': address,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'medicalInfo': medicalInfo?.toMap(),
      'preferences': preferences?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phone: map['phone'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      gender: map['gender'],
      profileImagePath: map['profileImagePath'],
      address: map['address'],
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
      medicalInfo: map['medicalInfo'] != null
          ? MedicalInfo.fromMap(map['medicalInfo'])
          : null,
      preferences: map['preferences'] != null
          ? AppPreferences.fromMap(map['preferences'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImagePath,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    MedicalInfo? medicalInfo,
    AppPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'gender': gender,
      'profileImagePath': profileImagePath,
      'address': address,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'medicalInfo': medicalInfo?.toFirestore(),
      'preferences': preferences?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      profileImagePath: data['profileImagePath'],
      address: data['address'],
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      medicalInfo: data['medicalInfo'] != null
          ? MedicalInfo.fromFirestore(
              data['medicalInfo'] as Map<String, dynamic>,
            )
          : null,
      preferences: data['preferences'] != null
          ? AppPreferences.fromFirestore(
              data['preferences'] as Map<String, dynamic>,
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class MedicalInfo {
  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final String? doctorName;
  final String? doctorPhone;
  final String? insuranceProvider;
  final String? insuranceNumber;
  final double? height; // in cm
  final double? weight; // in kg
  final String? notes;

  MedicalInfo({
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.doctorName,
    this.doctorPhone,
    this.insuranceProvider,
    this.insuranceNumber,
    this.height,
    this.weight,
    this.notes,
  });

  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;

    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  Map<String, dynamic> toMap() {
    return {
      'bloodType': bloodType,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'insuranceProvider': insuranceProvider,
      'insuranceNumber': insuranceNumber,
      'height': height,
      'weight': weight,
      'notes': notes,
    };
  }

  factory MedicalInfo.fromMap(Map<String, dynamic> map) {
    return MedicalInfo(
      bloodType: map['bloodType'],
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      doctorName: map['doctorName'],
      doctorPhone: map['doctorPhone'],
      insuranceProvider: map['insuranceProvider'],
      insuranceNumber: map['insuranceNumber'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      notes: map['notes'],
    );
  }

  MedicalInfo copyWith({
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? doctorName,
    String? doctorPhone,
    String? insuranceProvider,
    String? insuranceNumber,
    double? height,
    double? weight,
    String? notes,
  }) {
    return MedicalInfo(
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'bloodType': bloodType,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'insuranceProvider': insuranceProvider,
      'insuranceNumber': insuranceNumber,
      'height': height,
      'weight': weight,
      'notes': notes,
    };
  }

  // Create from Firestore document
  factory MedicalInfo.fromFirestore(Map<String, dynamic> data) {
    return MedicalInfo(
      bloodType: data['bloodType'],
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      doctorName: data['doctorName'],
      doctorPhone: data['doctorPhone'],
      insuranceProvider: data['insuranceProvider'],
      insuranceNumber: data['insuranceNumber'],
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      notes: data['notes'],
    );
  }
}

class AppPreferences {
  final bool notificationsEnabled;
  final bool reminderSounds;
  final int reminderInterval; // minutes before dose
  final ThemeMode themeMode;
  final String language;
  final bool biometricAuth;
  final bool autoBackup;

  AppPreferences({
    this.notificationsEnabled = true,
    this.reminderSounds = true,
    this.reminderInterval = 15,
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.biometricAuth = false,
    this.autoBackup = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'reminderSounds': reminderSounds,
      'reminderInterval': reminderInterval,
      'themeMode': themeMode.toString(),
      'language': language,
      'biometricAuth': biometricAuth,
      'autoBackup': autoBackup,
    };
  }

  factory AppPreferences.fromMap(Map<String, dynamic> map) {
    return AppPreferences(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      reminderSounds: map['reminderSounds'] ?? true,
      reminderInterval: map['reminderInterval'] ?? 15,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString() == map['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      language: map['language'] ?? 'en',
      biometricAuth: map['biometricAuth'] ?? false,
      autoBackup: map['autoBackup'] ?? true,
    );
  }

  AppPreferences copyWith({
    bool? notificationsEnabled,
    bool? reminderSounds,
    int? reminderInterval,
    ThemeMode? themeMode,
    String? language,
    bool? biometricAuth,
    bool? autoBackup,
  }) {
    return AppPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderSounds: reminderSounds ?? this.reminderSounds,
      reminderInterval: reminderInterval ?? this.reminderInterval,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      autoBackup: autoBackup ?? this.autoBackup,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'reminderSounds': reminderSounds,
      'reminderInterval': reminderInterval,
      'themeMode': themeMode.toString(),
      'language': language,
      'biometricAuth': biometricAuth,
      'autoBackup': autoBackup,
    };
  }

  // Create from Firestore document
  factory AppPreferences.fromFirestore(Map<String, dynamic> data) {
    return AppPreferences(
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      reminderSounds: data['reminderSounds'] ?? true,
      reminderInterval: data['reminderInterval'] ?? 15,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString() == data['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      language: data['language'] ?? 'en',
      biometricAuth: data['biometricAuth'] ?? false,
      autoBackup: data['autoBackup'] ?? true,
    );
  }
}

// -------------------- NOTIFICATION MODELS --------------------
enum NotificationType {
  medicationReminder,
  lowStock,
  medicationTaken,
  missedDose,
  refillReminder,
  appointmentReminder,
  waterReminder,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? medicationId;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
    this.medicationId,
    this.data,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'isRead': isRead,
      'medicationId': medicationId,
      'data': data,
    };
  }

  // Create from Map
  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.medicationReminder,
      ),
      isRead: map['isRead'] ?? false,
      medicationId: map['medicationId'],
      data: map['data'],
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? medicationId,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      medicationId: medicationId ?? this.medicationId,
      data: data ?? this.data,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'isRead': isRead,
      'medicationId': medicationId,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory NotificationItem.fromFirestore(Map<String, dynamic> data) {
    return NotificationItem(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.medicationReminder,
      ),
      isRead: data['isRead'] ?? false,
      medicationId: data['medicationId'],
      data: data['data'] as Map<String, dynamic>?,
    );
  }
}

// -------------------- APPOINTMENT MODELS --------------------
class DoctorAppointment {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final String? location;
  final String? address;
  final String? phoneNumber;
  final String? notes;
  final AppointmentStatus status;
  final String? reminderNote;
  final int? reminderMinutesBefore;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DoctorAppointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.appointmentDate,
    required this.appointmentTime,
    this.location,
    this.address,
    this.phoneNumber,
    this.notes,
    this.status = AppointmentStatus.scheduled,
    this.reminderNote,
    this.reminderMinutesBefore,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTimeHour': appointmentTime.hour,
      'appointmentTimeMinute': appointmentTime.minute,
      'location': location,
      'address': address,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'status': status.toString(),
      'reminderNote': reminderNote,
      'reminderMinutesBefore': reminderMinutesBefore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map
  factory DoctorAppointment.fromMap(Map<String, dynamic> map) {
    return DoctorAppointment(
      id: map['id'],
      doctorName: map['doctorName'],
      specialty: map['specialty'],
      appointmentDate: DateTime.parse(map['appointmentDate']),
      appointmentTime: TimeOfDay(
        hour: map['appointmentTimeHour'],
        minute: map['appointmentTimeMinute'],
      ),
      location: map['location'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      notes: map['notes'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => AppointmentStatus.scheduled,
      ),
      reminderNote: map['reminderNote'],
      reminderMinutesBefore: map['reminderMinutesBefore'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTimeHour': appointmentTime.hour,
      'appointmentTimeMinute': appointmentTime.minute,
      'location': location,
      'address': address,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'status': status.toString(),
      'reminderNote': reminderNote,
      'reminderMinutesBefore': reminderMinutesBefore,
      'createdAt': id.isEmpty
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory DoctorAppointment.fromFirestore(Map<String, dynamic> data) {
    return DoctorAppointment(
      id: data['id'] ?? '',
      doctorName: data['doctorName'] ?? '',
      specialty: data['specialty'] ?? '',
      appointmentDate:
          (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: TimeOfDay(
        hour: data['appointmentTimeHour'] ?? 0,
        minute: data['appointmentTimeMinute'] ?? 0,
      ),
      location: data['location'],
      address: data['address'],
      phoneNumber: data['phoneNumber'],
      notes: data['notes'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => AppointmentStatus.scheduled,
      ),
      reminderNote: data['reminderNote'],
      reminderMinutesBefore: data['reminderMinutesBefore'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method for updates
  DoctorAppointment copyWith({
    String? id,
    String? doctorName,
    String? specialty,
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    String? location,
    String? address,
    String? phoneNumber,
    String? notes,
    AppointmentStatus? status,
    String? reminderNote,
    int? reminderMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorAppointment(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      location: location ?? this.location,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      reminderNote: reminderNote ?? this.reminderNote,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  cancelled,
  completed,
  rescheduled,
  noShow,
}
