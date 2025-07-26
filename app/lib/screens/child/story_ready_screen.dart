import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/story.dart';
import '../../services/auth_service.dart';
import '../../generated/app_localizations.dart';

enum ApprovalMode { auto, app, email }

class StoryReadyScreen extends StatefulWidget {
  final Story story;
  final ApprovalMode approvalMode;
  
  const StoryReadyScreen({
    super.key,
    required this.story,
    required this.approvalMode,
  });

  @override
  State<StoryReadyScreen> createState() => _StoryReadyScreenState();
}

class _StoryReadyScreenState extends State<StoryReadyScreen> with TickerProviderStateMixin {
  late AnimationController _mascotSlideController;
  late Animation<double> _mascotSlideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Mascot slide-down animation
    _mascotSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _mascotSlideAnimation = Tween<double>(
      begin: 0.23, // Original position from ProcessingScreen
      end: 0.35,   // Lower position to make room for text and buttons
    ).animate(CurvedAnimation(
      parent: _mascotSlideController,
      curve: Curves.easeInOut,
    ));
    
    // Start the slide animation
    _mascotSlideController.forward();
  }

  @override
  void dispose() {
    _mascotSlideController.dispose();
    super.dispose();
  }

  String get _titleText {
    switch (widget.approvalMode) {
      case ApprovalMode.auto:
        return AppLocalizations.of(context)!.yourStoryIsReady;
      case ApprovalMode.app:
        return AppLocalizations.of(context)!.parentReviewPending;
      case ApprovalMode.email:
        return AppLocalizations.of(context)!.parentReviewPending;
    }
  }

  String? get _subtitleText {
    switch (widget.approvalMode) {
      case ApprovalMode.auto:
        return null;
      case ApprovalMode.app:
        return AppLocalizations.of(context)!.tapReviewToApprove;
      case ApprovalMode.email:
        return AppLocalizations.of(context)!.weWillNotifyWhenReady;
    }
  }

  String get _mascotFace {
    switch (widget.approvalMode) {
      case ApprovalMode.auto:
        return 'assets/images/face-1.svg'; // Happy face
      case ApprovalMode.app:
        return 'assets/images/face-3.svg'; // Hopeful/waiting face
      case ApprovalMode.email:
        return 'assets/images/face-3.svg'; // Hopeful/waiting face
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.secondary, // Plain yellow background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.secondary,
        child: SafeArea(
          child: Stack(
            children: [
              // Static clouds (no animation for this screen)
              _buildStaticClouds(screenSize),
              
              // Main content with animation
              AnimatedBuilder(
                animation: _mascotSlideAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: screenSize.height * _mascotSlideAnimation.value,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Title and subtitle in the space above mascot
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // Title
                              Text(
                                _titleText,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              // Subtitle (if exists)
                              if (_subtitleText != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _subtitleText!,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              
                              const SizedBox(height: 40),
                              
                              // Buttons based on approval mode
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Mascot - positioned lower
                        SizedBox(
                          width: screenSize.width * 0.588,
                          height: screenSize.width * 0.588,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Mascot body
                              SvgPicture.asset(
                                'assets/images/mascot-body-1.svg',
                                width: screenSize.width * 0.588,
                                height: screenSize.width * 0.588,
                                fit: BoxFit.contain,
                              ),
                              // Face on top - different expression based on mode
                              Positioned(
                                top: screenSize.width * 0.1176,
                                child: SvgPicture.asset(
                                  _mascotFace,
                                  width: screenSize.width * 0.144,
                                  height: screenSize.width * 0.072,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Close button (X) at top right for app and email modes
              if (widget.approvalMode != ApprovalMode.auto)
                Positioned(
                  top: 20,
                  right: 20,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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

  Widget _buildStaticClouds(Size screenSize) {
    return Stack(
      children: [
        // Biggest yellow cloud - static
        Positioned(
          top: screenSize.height * 0.35,
          left: screenSize.width * -0.4,
          child: SvgPicture.asset(
            'assets/images/cloud-1.svg',
            width: screenSize.width * 4.0,
            height: screenSize.width * 1.2,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFCF6A), // Yellow cloud
              BlendMode.srcIn,
            ),
          ),
        ),
        
        // Pink cloud - static
        Positioned(
          top: screenSize.height * 0.42,
          left: screenSize.width * 0.15,
          child: SvgPicture.asset(
            'assets/images/cloud-1.svg',
            width: screenSize.width * 1.32,
            height: screenSize.width * 0.55,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFFDFBBC6), // Pink cloud
              BlendMode.srcIn,
            ),
          ),
        ),
        
        // White cloud - static
        Positioned(
          top: screenSize.height * _getWhiteCloudPosition(screenSize),
          left: screenSize.width * 0.125,
          child: SvgPicture.asset(
            'assets/images/cloud-1.svg',
            width: screenSize.width * 0.77,
            height: screenSize.width * 0.385,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }

  double _getWhiteCloudPosition(Size screenSize) {
    if (screenSize.width < 600) {
      return 0.70; // Mobile: moved down more
    } else if (screenSize.width < 1200) {
      return 0.75; // Tablet: moved down more
    } else {
      return 0.80; // Desktop: moved down more
    }
  }

  Widget _buildActionButtons() {
    switch (widget.approvalMode) {
      case ApprovalMode.auto:
        return _buildAutoApproveButton();
      case ApprovalMode.app:
        return _buildAppReviewButton();
      case ApprovalMode.email:
        return const SizedBox.shrink(); // No buttons for email mode
    }
  }

  Widget _buildAutoApproveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _openStory(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 64),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 24),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.openStory,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppReviewButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _openParentReview(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 64),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 24),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.review,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStory() {
    Navigator.of(context).pushReplacementNamed(
      '/story-display',
      arguments: widget.story,
    );
  }

  void _openParentReview() {
    // Navigate to parent dashboard (which includes PIN screen)
    Navigator.of(context).pushNamed('/parent-dashboard');
  }
}