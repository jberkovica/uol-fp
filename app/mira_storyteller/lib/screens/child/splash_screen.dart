import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically navigate to the next screen after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/profile-select');
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/name
            const Text(
              'MIRA',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            // Optional animated character or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 77),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
