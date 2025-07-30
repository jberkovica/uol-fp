import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../generated/app_localizations.dart';

class ProcessingScreen extends StatefulWidget {
  final bool showCloseButton;
  final VoidCallback? onClose;
  
  const ProcessingScreen({
    super.key, 
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with TickerProviderStateMixin {
  late AnimationController _yellowCloudController;
  late AnimationController _pinkCloudController;
  late AnimationController _whiteCloudController;
  late Animation<double> _yellowCloudAnimation;
  late Animation<double> _pinkCloudAnimation;
  late Animation<double> _whiteCloudAnimation;
  

  @override
  void initState() {
    super.initState();
    
    // Yellow cloud - slowest, moves left
    _yellowCloudController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _yellowCloudAnimation = Tween<double>(
      begin: -0.5,
      end: -0.3, // 20% movement range
    ).animate(CurvedAnimation(
      parent: _yellowCloudController,
      curve: Curves.easeInOut,
    ));
    _yellowCloudController.repeat(reverse: true);
    
    // Pink cloud - medium speed, moves right
    _pinkCloudController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _pinkCloudAnimation = Tween<double>(
      begin: 0.05,
      end: 0.25, // 20% movement range
    ).animate(CurvedAnimation(
      parent: _pinkCloudController,
      curve: Curves.easeInOut,
    ));
    _pinkCloudController.repeat(reverse: true);
    
    // White cloud - medium speed, moves left
    _whiteCloudController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );
    _whiteCloudAnimation = Tween<double>(
      begin: 0.20,
      end: 0.05, // 15% movement range
    ).animate(CurvedAnimation(
      parent: _whiteCloudController,
      curve: Curves.easeInOut,
    ));
    _whiteCloudController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _yellowCloudController.dispose();
    _pinkCloudController.dispose();
    _whiteCloudController.dispose();
    super.dispose();
  }

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
              
              // 1. Biggest yellow cloud - animated
              AnimatedBuilder(
                animation: _yellowCloudAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: screenSize.height * 0.35,
                    left: screenSize.width * _yellowCloudAnimation.value,
                    child: child!,
                  );
                },
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
              
              // 2. Pink cloud - animated
              AnimatedBuilder(
                animation: _pinkCloudAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: screenSize.height * 0.42,
                    left: screenSize.width * _pinkCloudAnimation.value,
                    child: child!,
                  );
                },
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
                      AppLocalizations.of(context)!.magicIsHappening,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.textDark,
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
              
              // 3. White cloud - animated
              AnimatedBuilder(
                animation: _whiteCloudAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: screenSize.height * getWhiteCloudPosition(),
                    left: screenSize.width * _whiteCloudAnimation.value,
                    child: child!,
                  );
                },
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
              
              // Close button at top right - positioned at the end for proper z-index
              if (widget.showCloseButton)
                Positioned(
                  top: 20,
                  right: 20,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                      icon: SvgPicture.asset(
                        'assets/icons/x.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
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