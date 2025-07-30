import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  late AnimationController _mascotBounceController;
  late Animation<double> _mascotBounceAnimation;
  
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
      end: 0.38,   // Even lower position
    ).animate(CurvedAnimation(
      parent: _mascotSlideController,
      curve: Curves.easeInOut,
    ));
    
    // Mascot bounce animation (excited bouncing)
    _mascotBounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _mascotBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0, // Small amplitude bounce
    ).animate(CurvedAnimation(
      parent: _mascotBounceController,
      curve: Curves.easeInOut,
    ));
    
    // Start the slide animation, then start bouncing
    _mascotSlideController.forward().then((_) {
      _mascotBounceController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _mascotSlideController.dispose();
    _mascotBounceController.dispose();
    super.dispose();
  }

  String get _titleText {
    switch (widget.approvalMode) {
      case ApprovalMode.auto:
        return 'Your story is ready!';
      case ApprovalMode.app:
        return 'Parent review pending';
      case ApprovalMode.email:
        return 'Parent review pending';
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
        return 'assets/images/face-1.svg'; // Hopeful/waiting face
      case ApprovalMode.email:
        return 'assets/images/face-1.svg'; // Hopeful/waiting face
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
              // Yellow and violet clouds (bottom layer)
              _buildBackgroundClouds(screenSize),
              
              // Main content with animation (middle layer)
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
                        
                        // Mascot - positioned lower with bounce animation
                        AnimatedBuilder(
                          animation: _mascotBounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -_mascotBounceAnimation.value),
                              child: SizedBox(
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
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // White cloud (on top of mascot)
              _buildWhiteCloud(screenSize),
              
              // Close button (X) at top right for app and email modes (top layer)
              if (widget.approvalMode != ApprovalMode.auto)
                Positioned(
                  top: 20,
                  right: 20,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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

  Widget _buildBackgroundClouds(Size screenSize) {
    return Stack(
      children: [
        // Biggest yellow cloud - static
        Positioned(
          top: screenSize.height * 0.50,
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
        
        // Pink cloud - static (much lower)
        Positioned(
          top: screenSize.height * 0.65,
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
      ],
    );
  }

  Widget _buildWhiteCloud(Size screenSize) {
    return Positioned(
      top: screenSize.height * (_getWhiteCloudPosition(screenSize) + 0.05),
      left: screenSize.width * 0.1,
      child: SvgPicture.asset(
        'assets/images/cloud-1.svg',
        width: screenSize.width * 0.9, // Bigger
        height: screenSize.width * 0.45, // Bigger
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  double _getWhiteCloudPosition(Size screenSize) {
    if (screenSize.width < 600) {
      return 0.75; // Mobile: moved down even more
    } else if (screenSize.width < 1200) {
      return 0.80; // Tablet: moved down even more
    } else {
      return 0.85; // Desktop: moved down even more
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
    return Center(
      child: ElevatedButton(
        onPressed: () => _openStory(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 64),
        ),
        child: Text(
          'open',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
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
            SvgPicture.asset(
              'assets/icons/shield-check-filled.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
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