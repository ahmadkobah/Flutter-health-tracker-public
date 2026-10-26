import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../auth/data/auth_service.dart';

class PrescriptionService {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID - with validation
  String? get _currentUserId => _authService.currentUserId;

  // Check if user is authenticated
  bool get _isAuthenticated =>
      _authService.isSignedIn && _currentUserId != null;

  // Get user's prescription collection reference - SAFE version
  CollectionReference<Map<String, dynamic>> _getUserPrescriptionsCollection() {
    final userId = _currentUserId;
    if (!_isAuthenticated || userId == null) {
      throw 'User not authenticated or user ID is null';
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('prescriptions');
  }

  Future<void> addPrescription({
    required String extractedText,
    String? imageUrl,
    DateTime? scannedAt,
  }) async {
    try {
      final collection = _getUserPrescriptionsCollection();
      await collection.add({
        'text': extractedText,
        'imageUrl': imageUrl,
        'scannedAt': scannedAt ?? DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Prescription added successfully for user: $_currentUserId');
    } catch (e) {
      debugPrint('Error adding prescription: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    try {
      if (!_isAuthenticated) {
        debugPrint(
          'User not authenticated, returning empty prescriptions list',
        );
        return [];
      }

      final collection = _getUserPrescriptionsCollection();
      final query = await collection
          .orderBy('scannedAt', descending: true)
          .get();

      final prescriptions = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID for deletion
        return data;
      }).toList();

      debugPrint(
        'Retrieved ${prescriptions.length} prescriptions for user: $_currentUserId',
      );
      return prescriptions;
    } catch (e) {
      debugPrint('Error getting prescriptions: $e');
      return [];
    }
  }

  Future<void> deletePrescription(String docId) async {
    try {
      final collection = _getUserPrescriptionsCollection();
      await collection.doc(docId).delete();
      debugPrint(
        'Prescription deleted successfully: $docId for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('Error deleting prescription: $e');
      rethrow;
    }
  }
}
