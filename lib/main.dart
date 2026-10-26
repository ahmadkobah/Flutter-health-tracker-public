import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_options.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/data/auth_service.dart';
import 'core/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Main] Firebase initialization failed: $e');
  }
  try {
    await FirestoreService().enableOfflinePersistence();
  } catch (e) {
    debugPrint('[Main] Firestore offline persistence failed: $e');
  }
  runApp(const MedApp());
}

/// Main application widget
class MedApp extends StatelessWidget {
  const MedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return FutureBuilder<void>(
            future: themeProvider.isInitialized 
              ? Future.value() 
              : themeProvider.initialize(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MaterialApp(
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'MediCare+ - Medication Tracker',
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: themeProvider.themeMode,
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
