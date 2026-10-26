import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/auth/data/auth_service.dart';

/// Service for managing biometric authentication
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  
  factory BiometricService() => _instance;
  
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Secure storage keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _emailStorageKey = 'biometric_email';
  static const String _passwordStorageKey = 'biometric_password';

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      // Biometric not supported on web platform
      if (kIsWeb) {
        debugPrint('[BiometricService] Biometric authentication not supported on web');
        return false;
      }
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometric availability: $e');
      return false;
    }
  }

  /// Check if device has biometric enrolled
  Future<bool> hasBiometricsEnrolled() async {
    try {
      // Biometric not supported on web platform
      if (kIsWeb) {
        return false;
      }
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[BiometricService] Error checking enrolled biometrics: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      // Biometric not supported on web platform
      if (kIsWeb) {
        return [];
      }
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricService] Error getting available biometrics: $e');
      return [];
    }
  }

  /// Get biometric type names for display
  Future<String> getBiometricTypeNames() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return 'Not available';
      }
      
      final names = biometrics.map((type) {
        return switch (type) {
          BiometricType.face => 'Face Recognition',
          BiometricType.fingerprint => 'Fingerprint',
          BiometricType.iris => 'Iris Scanner',
          BiometricType.strong => 'Strong Biometric',
          BiometricType.weak => 'Weak Biometric',
        };
      }).toList();
      
      return names.join(', ');
    } catch (e) {
      debugPrint('[BiometricService] Error getting biometric names: $e');
      return 'Not available';
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    if (kIsWeb) {
      debugPrint('[BiometricService] Feature not supported on web');
      return false;
    }

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('[BiometricService] Biometric not available');
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
          useErrorDialogs: useErrorDialogs,
        ),
      );

      debugPrint('[BiometricService] Biometric authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      debugPrint('[BiometricService] Error during biometric authentication: $e');
      return false;
    }
  }

  /// Enable biometric login with stored credentials
  Future<void> enableBiometricLogin({
    required String email,
    required String password,
  }) async {
    if (kIsWeb) {
      debugPrint('[BiometricService] Feature not supported on web');
      return;
    }

    try {
      // Verify biometric is available first
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available on this device');
      }

      // Test biometric authentication
      final isAuthenticated = await authenticate(
        reason: 'Enable biometric login for MediCare+',
        useErrorDialogs: true,
      );

      if (!isAuthenticated) {
        throw Exception('Biometric authentication failed');
      }

      // Store credentials securely
      await _secureStorage.write(
        key: _emailStorageKey,
        value: email,
      );
      await _secureStorage.write(
        key: _passwordStorageKey,
        value: password,
      );
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: 'true',
      );

      // Update Firebase preference
      final userId = _authService.currentUserId;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({
              'preferences.biometricAuth': true,
              'preferences.updatedAt': FieldValue.serverTimestamp(),
            })
            .catchError((e) {
              debugPrint('[BiometricService] Error updating Firestore: $e');
              // Don't throw - local storage is more important
            });
      }

      debugPrint('[BiometricService] Biometric login enabled successfully');
    } catch (e) {
      debugPrint('[BiometricService] Error enabling biometric login: $e');
      // Clean up if something went wrong
      await disableBiometricLogin();
      rethrow;
    }
  }

  /// Disable biometric login and clear stored credentials
  Future<void> disableBiometricLogin() async {
    try {
      // Skip Firestore update on web, but allow local deletion
      if (!kIsWeb) {
        // Update Firebase preference
        final userId = _authService.currentUserId;
        if (userId != null) {
          await _firestore
              .collection('users')
              .doc(userId)
              .update({
                'preferences.biometricAuth': false,
                'preferences.updatedAt': FieldValue.serverTimestamp(),
              })
              .catchError((e) {
                debugPrint('[BiometricService] Error updating Firestore: $e');
              });
        }
      }

      await _secureStorage.delete(key: _emailStorageKey);
      await _secureStorage.delete(key: _passwordStorageKey);
      await _secureStorage.delete(key: _biometricEnabledKey);

      debugPrint('[BiometricService] Biometric login disabled');
    } catch (e) {
      debugPrint('[BiometricService] Error disabling biometric login: $e');
      rethrow;
    }
  }

  /// Check if biometric login is enabled locally
  Future<bool> isBiometricLoginEnabled() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometric login status: $e');
      return false;
    }
  }

  /// Get stored credentials for biometric login
  Future<Map<String, String>?> getStoredCredentials() async {
    try {
      final isEnabled = await isBiometricLoginEnabled();
      if (!isEnabled) {
        return null;
      }

      final email = await _secureStorage.read(key: _emailStorageKey);
      final password = await _secureStorage.read(key: _passwordStorageKey);

      if (email != null && password != null) {
        return {
          'email': email,
          'password': password,
        };
      }
      return null;
    } catch (e) {
      debugPrint('[BiometricService] Error getting stored credentials: $e');
      return null;
    }
  }

  /// Perform biometric login with stored credentials
  Future<bool> performBiometricLogin() async {
    if (kIsWeb) {
      debugPrint('[BiometricService] Feature not supported on web');
      return false;
    }

    try {
      // Check if biometric login is enabled
      final isEnabled = await isBiometricLoginEnabled();
      if (!isEnabled) {
        debugPrint('[BiometricService] Biometric login is not enabled');
        return false;
      }

      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('[BiometricService] Biometric not available');
        return false;
      }

      // Authenticate with biometric
      final isAuthenticated = await authenticate(
        reason: 'Unlock MediCare+ with biometric',
        useErrorDialogs: false,
      );

      if (!isAuthenticated) {
        debugPrint('[BiometricService] Biometric authentication failed');
        return false;
      }

      // Get stored credentials
      final credentials = await getStoredCredentials();
      if (credentials == null) {
        debugPrint('[BiometricService] No stored credentials found');
        return false;
      }

      // Sign in with stored credentials
      await _authService.signInWithEmailAndPassword(
        email: credentials['email']!,
        password: credentials['password']!,
      );

      debugPrint('[BiometricService] Biometric login successful');
      return true;
    } catch (e) {
      debugPrint('[BiometricService] Error performing biometric login: $e');
      return false;
    }
  }

  /// Clear all biometric data (for logout or account deletion)
  Future<void> clearBiometricData() async {
    try {
      await disableBiometricLogin();
      debugPrint('[BiometricService] Biometric data cleared');
    } catch (e) {
      debugPrint('[BiometricService] Error clearing biometric data: $e');
    }
  }

  /// Get biometric status (for settings page)
  Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      final isAvailable = await isBiometricAvailable();
      final isEnabled = await isBiometricLoginEnabled();
      final biometricTypes = await getBiometricTypeNames();

      return {
        'isAvailable': isAvailable,
        'isEnabled': isEnabled,
        'biometricTypes': biometricTypes,
      };
    } catch (e) {
      debugPrint('[BiometricService] Error getting biometric status: $e');
      return {
        'isAvailable': false,
        'isEnabled': false,
        'biometricTypes': 'Not available',
      };
    }
  }
}
