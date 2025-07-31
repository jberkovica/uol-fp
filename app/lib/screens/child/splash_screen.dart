import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';

// Custom clipper for angled ellipse curve
class AngledEllipseClipper extends CustomClipper<Path> {
  final double screenWidth;
  final double screenHeight;

  AngledEllipseClipper({required this.screenWidth, required this.screenHeight});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Line to bottom right
    path.lineTo(size.width, size.height);
    
    // Line up the right side to start of curve
    path.lineTo(size.width, size.height * 0.4);
    
    // Create simple smooth curve to match design file
    // Single clean elliptical curve from right to left
    path.cubicTo(
      size.width * 0.75, size.height * 0.1,  // First control point
      size.width * 0.25, size.height * 0.1,  // Second control point
      0, size.height * 0.4,                  // End point
    );
    
    // Close the path
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Auto navigate after delay with simple auth check
    Future.delayed(const Duration(seconds: 2), () async {
      if (!context.mounted) return;
      
      // Wait briefly for Supabase to restore auth state after page reload
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!context.mounted) return;
      
      // Simple routing: authenticated → profile select, not authenticated → login
      final authService = AuthService.instance;
      
      // On mobile apps, users stay logged in indefinitely
      // On web, session expires after 7 days of inactivity for security
      if (authService.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/profile-select');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.secondary, // Yellow background
        child: Stack(
          children: [
            // Violet angled curved shape anchored to bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: AngledEllipseClipper(
                  screenWidth: screenSize.width,
                  screenHeight: screenSize.height,
                ),
                child: Container(
                  height: screenSize.height * 0.5, // 50% of screen height
                  decoration: const BoxDecoration(
                    color: AppColors.primary, // Violet color
                  ),
                ),
              ),
            ),

            // MIRA SVG logo positioned in upper area
            Positioned(
              top: screenSize.height * 0.25, // Position in upper area
              left: 0,
              right: 0,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/mira-logo.svg',
                  width: 150,
                  height: 60,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary, // Violet color for the logo
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            
            // Face smile - positioned in the purple curved area like upload screen
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenSize.height * 0.5, // Same height as purple area
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: screenSize.height * 0.05),
                    child: SvgPicture.asset(
                      'assets/images/face-1.svg',
                      width: 100,
                      height: 50,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
