# MediCare+ (Flutter Health Tracker)

MediCare+ is a cross-platform Flutter app that helps people manage their daily health routine:
medications and dose reminders, doctor appointments, a meal schedule, water intake and a personal
health profile. All user data is stored per user in Firebase (Authentication and Cloud Firestore).

---

## Table of Contents

1. [Overview](#overview)
2. [Project Status](#project-status)
3. [How It Works](#how-it-works)
4. [Features and Screens](#features-and-screens)
5. [Technology Stack](#technology-stack)
6. [Project Structure](#project-structure)
7. [Getting Started](#getting-started)
8. [Configuration](#configuration)
9. [Data Model](#data-model)
10. [Testing](#testing)
11. [Known Issues](#known-issues)
12. [License](#license)

---

## Overview

### Purpose

People who take several medications, see different doctors and try to follow a diet often keep
this information in many places: paper notes, pill boxes, calendars and memory. Doses are missed,
appointments are forgotten and there is no simple overview of the day.

MediCare+ brings these tasks into one mobile app. The user signs in, adds their medications with a
time slot and weekdays, and the app schedules local reminders. The home dashboard shows today's
progress, the next appointment and a water intake tracker.

### Intended users

- Patients who take regular medication and want reminders and a daily overview.
- People who want to plan meals, track water intake and keep their medical data in one place.
- Family members who help someone else manage their medication.

### Main capabilities

- Email/password sign-up and sign-in, Google Sign-In and password reset (Firebase Authentication)
- Optional biometric login (fingerprint / Face ID) on supported devices
- Medication list with add, edit, delete, "taken" tracking and scheduled local reminders
- Prescription scanning with the camera and on-device text recognition (Google ML Kit)
- Doctor appointments with status, location and reminder note
- Nutrition schedule (Breakfast, Lunch, Dinner, Snacks) with dishes and weight in grams
- Water intake reminder with a daily glass counter
- In-app notification center
- User profile with medical information, BMI and settings (theme, notifications, language)
- Light and dark theme

---

## Project Status

The app is a **working prototype (version 1.0.0+1)**. The core flows (authentication,
medications, appointments, nutrition, water tracking, notifications, profile) read and write real
data in Firestore. Several settings and onboarding actions are user interface only.

| Area | Status | Notes |
|------|--------|-------|
| Authentication (email, Google, reset) | Working | Firebase Authentication |
| Biometric login | Working on mobile | Not available on web |
| Medications and reminders | Working | Firestore + `flutter_local_notifications` |
| Prescription OCR | Working on Android/iOS | Not supported on web; scanned text is saved as plain text |
| Doctor appointments | Working | Creates sample appointments on first open if the list is empty |
| Nutrition schedule | Working | Stored under the user document |
| Water reminder | Working | Glass counter and reminder interval in Firestore |
| Notifications page | Working | In-app list stored in Firestore |
| Profile and settings | Partly working | Some actions only show a message (see [Known Issues](#known-issues)) |
| Profile setup wizard after sign-up | UI only | Entered values are not saved |
| Push notifications (FCM), analytics, cloud storage | Not implemented | Packages are declared but not used |
| Automated tests | Not present | No `test/` folder |

---

## How It Works

### Application layers

```
+-------------------------------------------------------------+
|                    Presentation (Flutter UI)                 |
|  Splash, Onboarding, Login, Sign-up, Home, Medications,      |
|  Nutrition, Appointments, Profile, Settings, Notifications   |
+------------------------------+------------------------------+
                               |
+------------------------------v------------------------------+
|            State and dependency injection (provider)         |
|  AuthService, FirestoreService, ThemeProvider (ChangeNotifier)|
+------------------------------+------------------------------+
                               |
+------------------------------v------------------------------+
|                  Feature services (data layer)               |
|  MedicationService, AppointmentService, NutritionSchedule-   |
|  Service, DrinkWaterReminderService, NotificationService,    |
|  PrescriptionService, ProfileService, BiometricService       |
+-------+---------------------+---------------------+---------+
        |                     |                     |
+-------v-------+   +---------v---------+   +-------v---------+
| Firebase Auth |   | Cloud Firestore   |   | Device services |
| email, Google |   | per-user data,    |   | local notific., |
|               |   | offline cache     |   | biometrics, OCR,|
|               |   |                   |   | secure storage, |
|               |   |                   |   | shared prefs    |
+---------------+   +-------------------+   +-----------------+
```

### Typical flow

1. `main.dart` initializes Firebase with `DefaultFirebaseOptions.currentPlatform` and enables
   Firestore offline persistence.
2. `MedApp` registers `AuthService`, `FirestoreService` and `ThemeProvider` with `provider`. The
   theme mode is loaded from `shared_preferences`.
3. The splash screen waits briefly. If biometric login is enabled and available, it signs the user
   in with the credentials kept in secure storage and opens the home page.
4. Otherwise the user sees the onboarding screen, then the login screen (email/password, Google
   Sign-In, forgot password, biometric login) or the sign-up screen.
5. After sign-up, a three-step setup (basic, medical and lifestyle information) is shown, then the
   home page.
6. The home page shows the dashboard, quick actions, today's overview, the next appointment and
   the water reminder. A bottom navigation bar links to Medications, Nutrition, Appointments and
   Profile.
7. Each feature service reads and writes documents under `users/{uid}` in Firestore. Medication
   reminders are scheduled on the device with `flutter_local_notifications` and the `timezone`
   package.

---

## Features and Screens

### Authentication (`lib/features/auth`)

- **Splash screen**: tries biometric login, then moves to onboarding.
- **Onboarding**: short introduction pages with a skip option.
- **Login**: email and password, Google Sign-In, "Forgot Password" dialog (Firebase reset email)
  and a biometric login button when it is enabled.
- **Sign-up**: creates a Firebase user and a `users/{uid}` document; Google sign-up is supported.
- **Validators**: input checks for email, password and other form fields.

### Home (`lib/features/home`)

- **Dashboard** with greeting and a notification bell that opens the notifications page.
- **Quick actions**: My Medications (with active count), Add New Medication, Scan Rx.
- **Today's overview**: medication progress for the day.
- **Next appointment** card.
- **Drink water reminder**: daily glass counter, reminder interval in minutes, reset per day.
- **Notifications page**: list of in-app notifications (medication reminder, low stock, taken,
  missed dose, refill, appointment, water), with mark as read, mark all read, delete and clear all.

### Medications (`lib/features/medications`)

- **Medication list**: search, cards per medication, mark as taken.
- **Add / edit medication**: name, dose, type (tablet, capsule, liquid, injection, cream, drops,
  inhaler, patch, spray, other), time slot (morning, afternoon, evening, night), weekdays, start
  and optional end date, prescriber, instructions, side effects, notes and "remind me" minutes
  before the dose.
- **Medication details**: full information and history.
- **Reminders**: for every selected weekday, a repeating local notification is scheduled at the
  slot time minus the reminder offset (`zonedSchedule` with `dayOfWeekAndTime`).
- **Statistics in the service layer**: today's progress, adherence, count by type, upcoming doses.
- **Prescription OCR**: takes a photo with the camera, extracts the text with ML Kit text
  recognition and saves the text to `users/{uid}/prescriptions`.

### Nutrition (`lib/features/nutrition`)

- **Nutrition schedule**: four meals (Breakfast, Lunch, Dinner, Snacks). Each dish has a name and a
  weight in grams. Dishes can be added, edited and removed, and the whole schedule can be saved.
- **Water reminder service**: stores the water settings used by the home page widget.

### Appointments (`lib/features/appointments`)

- List of doctor appointments as a live Firestore stream.
- Create an appointment with doctor name and specialty (required), date, time, location/clinic,
  address, phone, notes, reminder note and reminder minutes.
- Cancel (delete) an appointment. The service also supports update, status change, search and
  filter by date.

### Profile (`lib/features/profile`)

- **Profile page**: personal data, medical information, BMI, health insights and profile
  completeness, logout.
- **Edit profile**: personal information, emergency contact and medical information.
- **Setup wizard** after sign-up: Complete Profile, Medical Info, Lifestyle Info.

### Settings (`lib/features/settings`)

- Notifications: push notifications toggle, reminder sounds, default reminder time.
- Appearance: light, dark or system theme.
- Security and privacy: biometric authentication setup, privacy policy and terms pages.
- Data management: auto backup flag, export data, import data.
- Language and region, About (version 1.0.0, help, rate, share), Danger Zone (clear data, delete
  account).

---

## Technology Stack

| Area | Technology | Purpose |
|------|------------|---------|
| Framework | Flutter (Dart SDK `>=3.8.1 <4.0.0`) | Cross-platform UI |
| State management | `provider` ^6.1.2 | Dependency injection and theme state |
| Backend | `firebase_core` ^3.6.0 | Firebase initialization |
| Authentication | `firebase_auth` ^5.3.1, `google_sign_in` ^6.1.5 | Email/password and Google sign-in |
| Database | `cloud_firestore` ^5.4.3 | User data with offline persistence |
| Notifications | `flutter_local_notifications` ^17.2.3, `timezone` ^0.9.2 | Scheduled medication reminders |
| Biometrics | `local_auth` ^2.3.0 | Fingerprint / Face ID |
| Secure storage | `flutter_secure_storage` ^9.0.0 | Credentials for biometric login |
| Local settings | `shared_preferences` ^2.3.2 | Theme mode |
| OCR | `google_mlkit_text_recognition` ^0.15.0 | Prescription text recognition |
| Camera / images | `image_picker` ^1.1.2 | Prescription photo |
| Formatting | `intl` ^0.19.0 | Date formatting |
| Linting | `flutter_lints` ^5.0.0 | Static analysis |

Declared in `pubspec.yaml` but **not imported** anywhere in `lib/`: `firebase_storage`,
`firebase_analytics`, `firebase_messaging`, `connectivity_plus`, `cached_network_image`,
`permission_handler`, `email_validator` and the umbrella package `google_ml_kit`.

Android build: Kotlin Gradle scripts, Java/JVM target 11, Google Services Gradle plugin and core
library desugaring (needed by `flutter_local_notifications`).

---

## Project Structure

```
lib/
|-- main.dart                        App entry, Firebase init, providers, theme
|-- core/
|   |-- models/
|   |   `-- models.dart              All data classes and enums
|   |-- services/
|   |   |-- biometric_service.dart   Biometric login and secure credential storage
|   |   |-- firebase_options.dart    Firebase options per platform
|   |   `-- firestore_service.dart   Shared Firestore access (profile, medications, logs)
|   |-- theme/
|   |   |-- app_theme.dart           Light and dark themes
|   |   `-- theme_provider.dart      Theme mode (ChangeNotifier)
|   `-- widgets/
|       `-- shared_widgets.dart      Header, bottom navigation, avatar, checkbox
`-- features/
    |-- appointments/
    |   |-- data/appointment_service.dart
    |   `-- presentation/doctor_appointment_page.dart
    |-- auth/
    |   |-- data/auth_service.dart, validators.dart
    |   `-- presentation/splash, onboarding, login, signup screens
    |-- home/
    |   |-- data/notification_service.dart
    |   `-- presentation/home_page, notifications_page, drink_water_reminder
    |-- medications/
    |   |-- data/medication_service.dart, prescription_service.dart
    |   `-- presentation/medication_list, add_medication, medication_details,
    |                    prescription_ocr pages
    |-- nutrition/
    |   |-- data/nutrition_schedule_service.dart, drink_water_reminder_service.dart
    |   `-- presentation/nutrition_schedule_page, drink_water_reminder
    |-- profile/
    |   |-- data/profile_service.dart
    |   `-- presentation/profile, profile_edit, complete_profile,
    |                    medical_info, lifestyle_info screens
    `-- settings/
        `-- presentation/settings_page.dart
```

Other top-level folders: `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` (Flutter
platform runners) and `firebase.json` (FlutterFire configuration).

---

## Getting Started

### Prerequisites

- Flutter SDK with Dart 3.8.1 or newer (Flutter 3.32 or newer)
- Android Studio with an Android emulator or device, and/or Xcode for iOS/macOS
- A Firebase project with Authentication and Cloud Firestore enabled (see
  [Configuration](#configuration))
- Optional: FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### Install

```bash
git clone https://github.com/ahmadkobah/Flutter-health-tracker-public.git
cd Flutter-health-tracker-public
flutter pub get
```

### Run

```bash
flutter devices          # list connected devices and emulators
flutter run              # run on the selected device
flutter run -d chrome    # web (no OCR, no biometric login)
```

### Build

```bash
flutter build apk --release      # Android APK
flutter build appbundle          # Android App Bundle
flutter build ios --release      # iOS (on macOS with Xcode)
flutter build web                # Web
```

The Android release build is currently signed with the debug key (`signingConfigs.debug` in
`android/app/build.gradle.kts`). Add your own signing configuration before publishing.

---

## Configuration

### Firebase

The app needs a Firebase project. To use your own project:

1. Create a Firebase project and enable **Authentication** (Email/Password and Google providers)
   and **Cloud Firestore**.
2. Register the Android app with the package name `com.company.MedicarePlus` and the iOS app.
3. Run `flutterfire configure`. It creates the Firebase options file and the platform files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `lib/firebase_options.dart` (the app imports it from `lib/core/services/firebase_options.dart`;
     move the file or update the import)
4. For Google Sign-In, add the SHA-1 fingerprint of your signing key in the Firebase console. On
   web, the login and sign-up screens pass a web client ID to `GoogleSignIn`.
5. Add Firestore security rules so that each user can only read and write `users/{uid}` and its
   subcollections. No rules file is included in this repository.

Firebase options are defined for Android, iOS, macOS, Windows and web. Linux is not configured and
throws `UnsupportedError`.

### Device permissions

- Android (`AndroidManifest.xml`): `CAMERA`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`,
  `USE_BIOMETRIC`, `USE_FINGERPRINT`.
- iOS (`Info.plist`): camera, photo library, Face ID and biometrics usage descriptions.

### Local settings

- Theme mode: `shared_preferences`.
- Biometric login: email, password and an enabled flag in `flutter_secure_storage`.

---

## Data Model

### Firestore layout

```
users/{uid}                          UserProfile fields, preferences, last login
|-- medications/{id}                 Medication
|-- medicationLogs/{id}              MedicationLog (medicationId, takenTime, notes)
|-- appointments/{id}                DoctorAppointment
|-- notifications/{id}               NotificationItem
|-- prescriptions/{id}               Scanned prescription text
|-- water_settings/current_settings  Glasses today, interval, reset date
`-- nutrition/current_schedule
    |-- breakfast/{dishId}           Dish (name, weight in grams)
    |-- lunch/{dishId}
    |-- dinner/{dishId}
    `-- snacks/{dishId}
```

### Main classes (`lib/core/models/models.dart`)

| Class / enum | Key fields |
|--------------|------------|
| `Medication` | id, name, dose, description, slot, schedule (weekdays), startDate, endDate, notes, prescriber, type, sideEffects, instructions, taken, lastTaken, reminderMinutesBefore |
| `TimeOfDaySlot` | morning, afternoon, evening, night |
| `MedicationType` | tablet, capsule, liquid, injection, cream, drops, inhaler, patch, spray, other |
| `MedicationLog` | id, medicationId, takenAt, notes, actualDose |
| `MedicationReminder` | id, medicationId, scheduledTime, isCompleted, completedAt |
| `UserProfile` | id, firstName, lastName, email, phone, dateOfBirth, gender, profileImagePath, address, emergencyContact, emergencyPhone, medicalInfo, preferences, createdAt, updatedAt |
| `MedicalInfo` | bloodType, allergies, medicalConditions, doctorName, doctorPhone, insuranceProvider, insuranceNumber, height (cm), weight (kg), notes; BMI is calculated |
| `AppPreferences` | notificationsEnabled, reminderSounds, reminderInterval, themeMode, language, biometricAuth, autoBackup |
| `NotificationItem` | id, title, message, timestamp, type, isRead, medicationId, data |
| `NotificationType` | medicationReminder, lowStock, medicationTaken, missedDose, refillReminder, appointmentReminder, waterReminder |
| `DoctorAppointment` | id, doctorName, specialty, appointmentDate, appointmentTime, location, address, phoneNumber, notes, status, reminderNote, reminderMinutesBefore, createdAt, updatedAt |
| `AppointmentStatus` | scheduled, confirmed, cancelled, completed, rescheduled |

---

## Testing

There are **no automated Dart tests** in this repository (no `test/` folder). The only test files
are the default native stubs `ios/RunnerTests/RunnerTests.swift` and
`macos/RunnerTests/RunnerTests.swift`.

Recommended checks before a change:

```bash
flutter analyze
flutter test        # once tests are added
```

Good first candidates for unit tests are `lib/features/auth/data/validators.dart`, the model
`toMap` / `fromMap` code in `models.dart` and the adherence and progress logic in
`MedicationService`.

---

## Known Issues

- **Profile setup wizard does not save data.** The Complete Profile, Medical Info and Lifestyle
  Info screens after sign-up do not call any service; the entered values are lost.
- **Settings actions that are placeholders**: Import Data, Rate App and Share App only show a
  message. "Clear All Data" and "Delete Account" in Settings only show a message and do not delete
  anything. The profile picture gallery picker is also a placeholder.
- **Account deletion is incomplete.** `AuthService` deletes the user document, medications and
  notifications, but looks for nutrition data in a top-level `nutrition_schedules` collection and
  prescriptions in a top-level `prescriptions` collection, while the app stores them under
  `users/{uid}`. Appointments, medication logs and water settings are not deleted.
- **Inconsistent nutrition path.** `FirestoreService.getNutritionScheduleStream()` reads
  `nutrition_schedules/{uid}`, but `NutritionScheduleService` writes to
  `users/{uid}/nutrition/current_schedule`.
- **Biometric login stores the password** in secure storage and replays it with
  email/password sign-in. Google-only accounts cannot use it.
- **Sample data**: the appointments page creates sample appointments with fictional doctors when
  the user has none.
- **Duplicate code**: `drink_water_reminder.dart` exists in both `home/presentation` and
  `nutrition/presentation`; only the home version is used by the home page.
- **Android leftovers**: two `MainActivity.kt` files (`com.company.MedicarePlus` and
  `com.example.flutter_application`), the app label is `flutter_application`, and the iOS display
  name is "Flutter Application". A second `google-services.json` exists in `android/`.
- **Android 13+ notifications**: the manifest does not declare `POST_NOTIFICATIONS` or exact alarm
  permissions, which scheduled reminders may need on newer Android versions.
- **Unused dependencies** listed in [Technology Stack](#technology-stack).

---

## License

This project is released under the **MIT License**. See the [LICENSE](LICENSE) file.

Author: Ahmad Kobah
