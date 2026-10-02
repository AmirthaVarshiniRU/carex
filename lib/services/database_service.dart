import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new user document
  Future<void> createUserDocument(String uid, {
    required String email,
    required String username,
  }) async {
    try {
      print('Attempting to create user document with uid: $uid');
      print('Document data: email=$email, username=$username');
      
      await _firestore.collection('users').doc(uid).set({
        'accountInfo': {
          'email': email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        },
        'profile': {
          'isCompleted': false,
        }
      });
      print('User document created successfully in Firestore');
      
      // Verify document was created
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print('Document verified - exists in Firestore');
        print('Document data: ${doc.data()}');
      } else {
        print('Warning: Document was not found after creation');
      }
    } catch (e) {
      print('Error creating user document: $e');
      print('Error details: ${e.toString()}');
      throw e;
    }
  }

  // Save user profile data
  Future<void> saveUserProfile(String uid, {
    required String name,
    required String age,
    required String height,
    required String weight,
    required String gender,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profile': {
          'name': name,
          'age': age,
          'height': height,
          'weight': weight,
          'gender': gender,
          'isCompleted': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      });
      print('User profile updated successfully');
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountInfo.lastLogin': FieldValue.serverTimestamp(),
      });
      print('Last login updated successfully');
    } catch (e) {
      print('Error updating last login: $e');
      throw e;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      print('User data retrieved successfully');
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      throw e;
    }
  }

  // Check if username exists
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('accountInfo.username', isEqualTo: username)
          .get();
      return result.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      throw e;
    }
  }

  // Delete user document
  Future<void> deleteUserDocument(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('User document deleted successfully');
    } catch (e) {
      print('Error deleting user document: $e');
      throw e;
    }
  }
} 