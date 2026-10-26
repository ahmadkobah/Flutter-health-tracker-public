import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static AuthService? _instance;
  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Create user account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName('$firstName $lastName');

      // Send email verification
      await credential.user?.sendEmailVerification();

      // Save user info locally
      await _saveUserInfo(credential.user!, firstName, lastName);

      // Save user info to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'email': credential.user!.email,
            'firstName': firstName,
            'lastName': lastName,
            'displayName': '$firstName $lastName',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected sign up error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      await _updateLastLogin();

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearUserInfo();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset password error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected reset password error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Update email
  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      debugPrint('Update email error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected update email error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Update password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('Update password error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected update password error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateUser({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user?.email == null) {
        throw Exception('No user email found for re-authentication.');
      }
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Re-authentication error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected re-authentication error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Delete user account
  Future<void> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      // Re-authenticate first
      await reauthenticateUser(password: password);

      // Delete user data from Firestore BEFORE deleting the auth account
      final userId = user.uid;
      await _deleteUserDataFromFirestore(userId);

      // Delete the user account
      await user.delete();

      // Clear local data
      await _clearUserInfo();
    } on FirebaseAuthException catch (e) {
      debugPrint('Delete account error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected delete account error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      if (user.emailVerified) {
        throw Exception('Email is already verified.');
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      debugPrint('Send verification error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected verification error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload current user to check verification status
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      await user.reload();
    } catch (e) {
      debugPrint('Reload user error: $e');
      throw Exception('Failed to reload user information.');
    }
  }

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;

  // Update user profile information
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update local storage if display name changed
      if (displayName != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_display_name', displayName);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Update profile error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected update profile error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Check if user exists with email using Firestore
  Future<bool> checkUserExists({required String email}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Check user exists error: $e');
      throw Exception('Failed to check if user exists. Please try again.');
    }
  }

  // Private helper methods
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please choose a stronger password.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection and try again.';
        break;
      case 'requires-recent-login':
        message =
            'This operation requires recent authentication. Please sign in again.';
        break;
      case 'invalid-credential':
        message = 'The credentials provided are invalid.';
        break;
      case 'credential-already-in-use':
        message =
            'This credential is already associated with a different user account.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed. Please contact support.';
        break;
      default:
        message = e.message ?? 'An authentication error occurred.';
        break;
    }
    return Exception(message);
  }

  Future<void> _saveUserInfo(
    User user,
    String firstName,
    String lastName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);
      await prefs.setString('user_display_name', '$firstName $lastName');
    } catch (e) {
      debugPrint('Error saving user info: $e');
      // Don't throw here as this is not critical for authentication
    }
  }

  Future<void> _updateLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error updating last login: $e');
      // Don't throw here as this is not critical for authentication
    }
  }

  Future<void> _clearUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_first_name');
      await prefs.remove('user_last_name');
      await prefs.remove('user_display_name');
      await prefs.remove('last_login');
    } catch (e) {
      debugPrint('Error clearing user info: $e');
      // Don't throw here as this is not critical
    }
  }

  // Get stored user info
  Future<Map<String, String?>> getStoredUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'user_id': prefs.getString('user_id'),
        'user_email': prefs.getString('user_email'),
        'user_first_name': prefs.getString('user_first_name'),
        'user_last_name': prefs.getString('user_last_name'),
        'user_display_name': prefs.getString('user_display_name'),
        'last_login': prefs.getString('last_login'),
      };
    } catch (e) {
      debugPrint('Error getting stored user info: $e');
      return {};
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, contains letter and number
    return password.length >= 8 &&
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  // Get password strength
  static String getPasswordStrength(String password) {
    if (password.length < 6) return 'Weak';
    if (password.length < 8) return 'Fair';
    if (RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return 'Strong';
    }
    if (RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
      return 'Good';
    }
    return 'Fair';
  }

  // Delete user data from Firestore
  Future<void> _deleteUserDataFromFirestore(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Delete user document
      batch.delete(firestore.collection('users').doc(userId));

      // Delete medications subcollection
      final medsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .get();
      for (var doc in medsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete nutrition schedules
      final nutritionSnapshot = await firestore
          .collection('nutrition_schedules')
          .doc(userId)
          .get();
      if (nutritionSnapshot.exists) {
        batch.delete(nutritionSnapshot.reference);
      }

      // Delete prescriptions
      final prescriptionsSnapshot = await firestore
          .collection('prescriptions')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in prescriptionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete notifications
      final notificationsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('User data deleted from Firestore for user: $userId');
    } catch (e) {
      debugPrint('Error deleting user data from Firestore: $e');
      throw Exception('Failed to delete user data. Please contact support.');
    }
  }
}
