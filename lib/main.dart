import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'firebase_options.dart';
import 'screens/entry_screen.dart';
import 'screens/app_introduction_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/user_details_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => app_auth.AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CAREX – Comprehensive Adaptive Rehabilitation Expert',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          primaryColor: const Color(0xFF059669),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF8FAFC), foregroundColor: Color(0xFF1E293B), elevation: 0, centerTitle: true),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            return snapshot.hasData ? const RoleBasedHome() : const EntryScreen();
          },
        ),
        routes: {
          '/intro': (_) => const AppIntroductionScreen(),
          '/signin': (_) => const SignInScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/profile_setup': (_) => const ProfileSetupScreen(),
          '/home': (_) => const RoleBasedHome(),
          '/accountSettings': (_) => const AccountSettingsScreen(),
          '/changePassword': (_) => const ChangePasswordScreen(),
          '/userDetails': (_) => const UserDetailsScreen(),
        },
      ),
    );
  }
}

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const EntryScreen();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data?.data() ?? {};
        final account = (data['accountInfo'] as Map?)?.cast<String, dynamic>() ?? {};
        final role = (account['role'] ?? data['role'] ?? 'Patient').toString().toLowerCase();
        return role == 'doctor' ? const DoctorDashboardScreen() : const HomeScreen();
      },
    );
  }
}
