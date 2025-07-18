import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../services/auth_service.dart';
import '../../services/app_state_service.dart';

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

    // Auto navigate after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!context.mounted) return;
      
      // Check if user is authenticated
      if (AuthService.instance.isAuthenticated) {
        // Check if there's a saved kid selection
        final savedKid = AppStateService.getSelectedKid();
        if (savedKid != null) {
          // Navigate directly to child home with saved kid
          Navigator.pushReplacementNamed(context, '/child-home', arguments: savedKid);
        } else {
          // No saved kid, go to profile selection
          Navigator.pushReplacementNamed(context, '/profile-select');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary, // Purple background
        child: Stack(
          children: [
            // Yellow angled curved shape anchored to bottom
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
                    color: AppColors.secondary, // Yellow color
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
                    AppColors.textLight, // White color for the logo
                    BlendMode.srcIn,
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
