import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../auth/data/auth_service.dart';

class NutritionScheduleService {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID - with validation
  String? get _currentUserId => _authService.currentUserId;

  // Check if user is authenticated
  bool get _isAuthenticated =>
      _authService.isSignedIn && _currentUserId != null;

  // Get user's nutrition document reference - SAFE version
  DocumentReference<Map<String, dynamic>> _getUserNutritionDocument() {
    final userId = _currentUserId;
    if (!_isAuthenticated || userId == null) {
      throw 'User not authenticated or user ID is null';
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .doc('current_schedule');
  }

  Future<List<Map<String, dynamic>>> getMeals(String mealType) async {
    try {
      if (!_isAuthenticated) {
        debugPrint('User not authenticated, returning empty meals list');
        return [];
      }

      final nutritionDoc = _getUserNutritionDocument();
      final mealCollection = nutritionDoc.collection(mealType.toLowerCase());
      final snapshot = await mealCollection
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );

      final meals = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID for deletion
        return data;
      }).toList();

      debugPrint(
        'Retrieved ${meals.length} meals for $mealType for user: $_currentUserId',
      );
      return meals;
    } catch (e) {
      debugPrint('[NutritionScheduleService] Error getting meals for $mealType: $e');
      return [];
    }
  }

  Future<void> addDish(String mealType, Map<String, dynamic> dish) async {
    try {
      final nutritionDoc = _getUserNutritionDocument();
      final mealCollection = nutritionDoc.collection(mealType.toLowerCase());
      await mealCollection
          .add({
            ...dish,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );
      debugPrint(
        'Dish added successfully to $mealType for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('[NutritionScheduleService] Error adding dish to $mealType: $e');
      rethrow;
    }
  }

  Future<void> removeDish(String mealType, String dishId) async {
    try {
      final nutritionDoc = _getUserNutritionDocument();
      final mealCollection = nutritionDoc.collection(mealType.toLowerCase());
      await mealCollection
          .doc(dishId)
          .delete()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );
      debugPrint(
        'Dish removed successfully from $mealType for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('[NutritionScheduleService] Error removing dish from $mealType: $e');
      rethrow;
    }
  }

  Future<void> updateDish(
    String mealType,
    String dishId,
    Map<String, dynamic> dish,
  ) async {
    try {
      final nutritionDoc = _getUserNutritionDocument();
      final mealCollection = nutritionDoc.collection(mealType.toLowerCase());
      await mealCollection
          .doc(dishId)
          .set({
            ...dish,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Firestore operation timed out - check network connection',
              );
            },
          );
      debugPrint(
        'Dish updated successfully in $mealType for user: $_currentUserId',
      );
    } catch (e) {
      debugPrint('[NutritionScheduleService] Error updating dish in $mealType: $e');
      rethrow;
    }
  }

  // Stream to listen to meal changes
  Stream<List<Map<String, dynamic>>> getMealsStream(String mealType) {
    try {
      if (!_isAuthenticated) {
        debugPrint('User not authenticated, returning empty stream');
        return Stream.value([]);
      }

      final nutritionDoc = _getUserNutritionDocument();
      return nutritionDoc
          .collection(mealType.toLowerCase())
          .snapshots()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: (sink) {
              sink.addError(Exception(
                'Firestore operation timed out - check network connection',
              ));
            },
          )
          .map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
    } catch (e) {
      debugPrint('[NutritionScheduleService] Error getting meals stream for $mealType: $e');
      return Stream.value([]);
    }
  }

  Future<void> setAllMeals(
    Map<String, List<Map<String, dynamic>>> meals,
  ) async {
    try {
      final nutritionDoc = _getUserNutritionDocument();
      final batch = FirebaseFirestore.instance.batch();

      for (final meal in meals.keys) {
        final mealCollection = nutritionDoc.collection(meal.toLowerCase());
        final snapshot = await mealCollection
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception(
                  'Firestore operation timed out - check network connection',
                );
              },
            );
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        for (final dish in meals[meal]!) {
          final newDoc = mealCollection.doc();
          batch.set(newDoc, {
            ...dish,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Firestore operation timed out - check network connection',
          );
        },
      );
      debugPrint('All meals set successfully for user: $_currentUserId');
    } catch (e) {
      debugPrint('[NutritionScheduleService] Error setting all meals: $e');
      rethrow;
    }
  }
}
