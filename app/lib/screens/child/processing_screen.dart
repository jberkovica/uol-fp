import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';

class ProcessingScreen extends StatelessWidget {
  final bool showCloseButton;
  final VoidCallback? onClose;
  
  const ProcessingScreen({
    super.key, 
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Responsive white cloud position
    double getWhiteCloudPosition() {
      if (screenSize.width < 600) {
        return 0.60; // Mobile: moved down from 55%
      } else if (screenSize.width < 1200) {
        return 0.65; // Tablet: moved down from 60%
      } else {
        return 0.75; // Desktop: moved down from 70%
      }
    }
    
    return Scaffold(
      backgroundColor: AppColors.secondary, // Plain yellow background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.secondary,
        child: SafeArea(
          child: Stack(
            children: [
              
              // 1. Biggest yellow cloud - moved up more
              Positioned(
                top: screenSize.height * 0.35, // 35% from top (was 50%)
                left: -screenSize.width * 0.5, // Extends off left edge
                child: SvgPicture.asset(
                  'assets/images/cloud-1.svg',
                  width: screenSize.width * 4.0, // 2x bigger yellow cloud
                  height: screenSize.width * 1.2, // Height proportionally bigger
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFFCF6A), // Yellow cloud
                    BlendMode.srcIn,
                  ),
                ),
              ),
              
              // 2. Pink cloud - moved up
              Positioned(
                top: screenSize.height * 0.42, // 42% from top (was 62%)
                left: screenSize.width * 0.1,
                child: SvgPicture.asset(
                  'assets/images/cloud-1.svg',
                  width: screenSize.width * 1.32, // 10% bigger pink cloud
                  height: screenSize.width * 0.55, // Height proportionally bigger
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFDFBBC6), // Pink cloud
                    BlendMode.srcIn,
                  ),
                ),
              ),
              
              // Main content - moved even lower
              Positioned(
                top: screenSize.height * 0.23, // 23% from top (was 20%)
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Text
                    Text(
                      'Magic is happening..',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 32, // Fixed font size
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 120), // Even more spacing to push mascot down
                    
                    // 5. Mascot - bigger and centered
                    SizedBox(
                      width: screenSize.width * 0.588, // 40% bigger mascot (0.42 * 1.4)
                      height: screenSize.width * 0.588,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Mascot body
                          SvgPicture.asset(
                            'assets/images/mascot-body-1.svg',
                            width: screenSize.width * 0.588, // 40% bigger mascot body
                            height: screenSize.width * 0.588,
                            fit: BoxFit.contain,
                          ),
                          // Face on top
                          Positioned(
                            top: screenSize.width * 0.1176, // Adjusted for bigger mascot but same face size
                            child: SvgPicture.asset(
                              'assets/images/face-2.svg',
                              width: screenSize.width * 0.144, // Keep face same size
                              height: screenSize.width * 0.072,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 3. White cloud - on top of mascot (after mascot in stack order)
              Positioned(
                top: screenSize.height * getWhiteCloudPosition(), // Responsive positioning
                left: screenSize.width * 0.15,
                child: SvgPicture.asset(
                  'assets/images/cloud-1.svg',
                  width: screenSize.width * 0.77, // 10% bigger white cloud
                  height: screenSize.width * 0.385, // Height proportionally bigger
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              
              // 4. Yellow star - aligned with white cloud
              Positioned(
                top: screenSize.height * (screenSize.width < 600 ? 0.55 : screenSize.width < 1200 ? 0.60 : 0.70), // Aligned with white cloud
                right: screenSize.width * 0.15,
                child: SvgPicture.asset(
                  'assets/images/star-1.svg',
                  width: screenSize.width * 0.07,
                  height: screenSize.width * 0.07,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFFDF88), // Yellow star
                    BlendMode.srcIn,
                  ),
                ),
              ),
              
              // Close button at top right - positioned at the end for proper z-index
              if (showCloseButton)
                Positioned(
                  top: 20,
                  right: 20,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        color: AppColors.textDark,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}