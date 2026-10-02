import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _checkLoggedInStatus();
  }
  
  Future<void> _checkLoggedInStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (isLoggedIn) {
      final email = prefs.getString('userEmail') ?? '';
      final displayName = prefs.getString('userName') ?? '';
      final uid = prefs.getString('userId') ?? '';
      final role = prefs.getString('userRole') ?? 'Patient';
      
      _user = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        emailVerified: true,
        role: role,
      );
    }
    
    notifyListeners();
  }

  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Checking if username is available...');
      // Check if username is already taken
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('accountInfo.username', isEqualTo: username)
          .get();
      
      if (usernameQuery.docs.isNotEmpty) {
        _error = 'Username is already taken';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Creating user account...');
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Updating display name...');
      await userCredential.user!.updateDisplayName(username);

      // Create initial user document in Firestore
      print('Creating user document in Firestore...');
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'accountInfo': {
          'email': email,
          'username': username,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        },
        'profile': {
          'isCompleted': false,
        },
        'settings': {
          'emailNotifications': true,
          'pushNotifications': true,
          'darkMode': false,
        },
      });

      // Update user model
      _user = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: username,
        emailVerified: userCredential.user!.emailVerified,
        role: role,
      );

      // Save login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', username);
      await prefs.setString('userId', _user!.uid);
      await prefs.setString('userRole', role);

      print('Sign up completed successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'This email is already registered';
          break;
        case 'invalid-email':
          _error = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          _error = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          _error = 'Password is too weak';
          break;
        default:
          _error = 'An error occurred: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      print('Error during sign up: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Attempting to sign in user...');
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User signed in successfully');
      
      // Check if user has completed profile setup
      final hasProfile = await hasCompletedProfile(userCredential.user!.uid);

      // Fetch user data to get role
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      final role = userDoc.data()?['accountInfo']?['role'] ?? 'Patient';

      // Update user model
      _user = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: userCredential.user!.displayName ?? '',
        emailVerified: userCredential.user!.emailVerified,
        role: role,
      );

      // Save login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', _user!.displayName ?? '');
      await prefs.setString('userId', _user!.uid);
      await prefs.setString('userRole', role);

      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'hasProfile': hasProfile,
        'uid': userCredential.user!.uid,
      };
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'user-not-found':
          _error = 'No user found with this email';
          break;
        case 'wrong-password':
          _error = 'Wrong password provided';
          break;
        case 'invalid-email':
          _error = 'Invalid email address';
          break;
        case 'user-disabled':
          _error = 'This account has been disabled';
          break;
        default:
          _error = 'An error occurred: ${e.message}';
      }
      notifyListeners();
      return {
        'success': false,
        'error': _error,
      };
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return {
        'success': false,
        'error': _error,
      };
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reauthenticate user before changing password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        
        // Change password
        await user.updatePassword(newPassword);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        _user = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update user in Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(updatedUser.displayName);
        
        // Update additional data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'displayName': updatedUser.displayName,
          'phoneNumber': updatedUser.phoneNumber,
          'additionalData': updatedUser.additionalData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _user = updatedUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  // Check if user has completed profile setup
  Future<bool> hasCompletedProfile(String uid) async {
    try {
      print('Checking if user has completed profile...');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (!doc.exists) {
        print('User document does not exist');
        return false;
      }
      
      final data = doc.data();
      final isCompleted = data?['profileCompleted'] ?? false;
      print('Profile completion status: $isCompleted');
      return isCompleted;
    } catch (e) {
      print('Error checking profile status: $e');
      return false;
    }
  }

  Future<void> updateUserMood(String mood) async {
    if (_user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userMood', mood);
      _user = _user!.copyWith(currentMood: mood);
      notifyListeners();
    } catch (e) {
      print('Error updating user mood: $e');
    }
  }
}