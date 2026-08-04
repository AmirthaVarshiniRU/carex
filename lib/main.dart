import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as app_auth; // Use alias for AuthProvider
import 'screens/entry_screen.dart';
import 'screens/app_introduction_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/user_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB_Coac8F4kpJz8O9L3V_1B2H1RzULWxl4",
        appId: "1:392161688120:android:56293bfa12991f8cc2c4cd",
        messagingSenderId: "392161688120",
        projectId: "adaptx-9d4e7",
        databaseURL: "https://adaptx-9d4e7-default-rtdb.firebaseio.com/",
      ),
    );
    await Firebase.initializeApp();
    print("✅ Firebase Initialized Successfully!");
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Removed 'const' keyword

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => app_auth.AuthProvider(), // Use the alias here
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CAREX – Comprehensive Adaptive Rehabilitation Expert',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          primaryColor: const Color(0xFF059669),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8FAFC),
            foregroundColor: Color(0xFF1E293B),
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return snapshot.hasData ? const HomeScreen() : const EntryScreen();
          },
        ),
        routes: {
          '/intro': (context) => const AppIntroductionScreen(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/profile_setup': (context) => const ProfileSetupScreen(),
          '/home': (context) => const HomeScreen(),
          '/accountSettings': (context) => const AccountSettingsScreen(),
          '/changePassword': (context) => const ChangePasswordScreen(),
          '/userDetails': (context) => const UserDetailsScreen(),
        },
      ),
    );
  }
}
