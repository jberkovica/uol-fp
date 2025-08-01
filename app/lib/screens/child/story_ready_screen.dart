import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/story.dart';
import '../../services/logging_service.dart';
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
  static final _logger = LoggingService.getLogger('StoryReadyScreen');
  
  late AnimationController _mascotSlideController;
  late Animation<double> _mascotSlideAnimation;
  late AnimationController _mascotBounceController;
  late Animation<double> _mascotBounceAnimation;
  
  // Real-time subscription state
  RealtimeChannel? _storySubscription;
  late ApprovalMode _currentApprovalMode;
  late Story _currentStory;
  
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
    
    // Initialize state
    _currentApprovalMode = widget.approvalMode;
    _currentStory = widget.story;
    
    // Start the slide animation, then start bouncing
    _mascotSlideController.forward().then((_) {
      _mascotBounceController.repeat(reverse: true);
    });
    
    // Start real-time subscription for approval modes that require it
    _setupStorySubscription();
  }

  @override
  void dispose() {
    _mascotSlideController.dispose();
    _mascotBounceController.dispose();
    _storySubscription?.unsubscribe();
    super.dispose();
  }

  String get _titleText {
    switch (_currentApprovalMode) {
      case ApprovalMode.auto:
        return AppLocalizations.of(context)!.yourStoryIsReady;
      case ApprovalMode.app:
        return AppLocalizations.of(context)!.parentReviewPending;
      case ApprovalMode.email:
        return AppLocalizations.of(context)!.parentReviewPending;
    }
  }

  String? get _subtitleText {
    switch (_currentApprovalMode) {
      case ApprovalMode.auto:
        return null;
      case ApprovalMode.app:
        return null; // Removed redundant subtitle
      case ApprovalMode.email:
        return null; // Removed redundant subtitle
    }
  }

  String get _mascotFace {
    switch (_currentApprovalMode) {
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
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppColors.textDark,
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
                        
                        const SizedBox(height: 120), // Match ProcessingScreen spacing
                        
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
                                        width: screenSize.width * 0.100, // Balanced face size
                                        height: screenSize.width * 0.050,
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
              if (_currentApprovalMode != ApprovalMode.auto)
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
    switch (_currentApprovalMode) {
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
          AppLocalizations.of(context)!.openStory,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppReviewButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () => _openParentReview(),
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
          AppLocalizations.of(context)!.review,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _openStory() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/story-display',
      (route) => route.settings.name == '/child-home',
      arguments: _currentStory,
    );
  }

  void _openParentReview() {
    // Navigate to parent dashboard (which includes PIN screen)
    Navigator.of(context).pushNamed('/parent-dashboard');
  }

  /// Setup real-time subscription for story status updates
  void _setupStorySubscription() {
    // Only subscribe if we're in approval modes that require it
    if (_currentApprovalMode == ApprovalMode.app || _currentApprovalMode == ApprovalMode.email) {
      _logger.i('Setting up real-time subscription for story: ${_currentStory.id}');
      
      _storySubscription = Supabase.instance.client
        .channel('story_${_currentStory.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'stories',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentStory.id,
          ),
          callback: (payload) {
            _handleStoryUpdate(payload);
          },
        )
        .subscribe();
        
      _logger.i('Real-time subscription active for story: ${_currentStory.id}');
    }
  }

  /// Handle real-time story updates
  void _handleStoryUpdate(PostgresChangePayload payload) {
    try {
      final newRecord = payload.newRecord;
      final updatedStory = Story.fromJson(newRecord);
        
      _logger.d('Story status updated: ${updatedStory.status}');
      
      // If story status changed to approved, update the state to show open button
      if (updatedStory.status == StoryStatus.approved && _currentApprovalMode != ApprovalMode.auto) {
        _logger.i('Story approved! Updating UI to show open button');
        
        // Unsubscribe since we no longer need updates
        _storySubscription?.unsubscribe();
        _storySubscription = null;
        
        if (mounted) {
          setState(() {
            _currentStory = updatedStory;
            _currentApprovalMode = ApprovalMode.auto;
          });
        }
      }
    } catch (e) {
      _logger.e('Error handling real-time story update: $e');
    }
  }
}