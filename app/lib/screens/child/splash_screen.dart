import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Auto navigate after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/profile-select');
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary, // Purple background
        child: Stack(
          children: [
            // Large partial yellow circle at bottom - matching your Figma design
            Positioned(
              bottom: -screenSize.height * 0.35,
              left: -screenSize.width * 0.15,
              child: Container(
                width: screenSize.width * 1.3,
                height: screenSize.width * 1.3,
                decoration: const BoxDecoration(
                  color: AppColors.secondary, // Yellow color
                  shape: BoxShape.circle,
                  // No shadows - flat design
                ),
              ),
            ),

            // MIRA SVG logo positioned in center
            Center(
              child: SvgPicture.asset(
                'assets/images/mira-logo.svg',
                width: 200,
                height: 80,
                colorFilter: const ColorFilter.mode(
                  AppColors.textLight, // White color for the logo
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
