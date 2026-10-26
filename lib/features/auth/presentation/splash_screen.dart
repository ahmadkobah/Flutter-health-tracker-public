import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../../../core/services/biometric_service.dart';
import '../../home/presentation/home_page.dart';

// ------------------ SPLASH SCREEN ------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricLogin();
  }

  Future<void> _checkBiometricLogin() async {
    // Wait 1.5 seconds to show splash screen
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check if biometric login is available and enabled
    final isEnabled = await _biometricService.isBiometricLoginEnabled();
    final isAvailable = await _biometricService.isBiometricAvailable();

    if (mounted) {
      if (isEnabled && isAvailable) {
        // Try biometric login
        final success = await _biometricService.performBiometricLogin();
        if (success && mounted) {
          // Biometric login successful, navigate to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
          return;
        }
      }

      // If biometric not available or failed, continue to onboarding
      _navigateToOnboarding();
    }
  }

  _navigateToOnboarding() {
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8364E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 50,
                  color: Color(0xFF6A5AE0),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "MediCare+",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your Health Companion",
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
