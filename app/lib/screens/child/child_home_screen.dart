import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_theme.dart';
import '../../generated/app_localizations.dart';
import '../../services/kid_service.dart';
import '../../services/app_state_service.dart';
import '../../models/story.dart';
import '../../models/kid.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/page_transitions.dart';
import '../child/profile_screen.dart';
import '../parent/pin_entry_screen.dart';


class ChildHomeScreen extends StatefulWidget {
  final Kid? kid;
  
  const ChildHomeScreen({super.key, this.kid});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}


class _ChildHomeScreenState extends State<ChildHomeScreen> with TickerProviderStateMixin {
  Kid? _selectedKid;
  List<Story> _stories = [];
  List<Story> _favouriteStories = [];
  List<Story> _latestStories = [];
  bool _isLoadingStories = false;
  int _currentNavIndex = 1; // Home tab is default (middle)
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Use kid passed from constructor first
    if (widget.kid != null) {
      _selectedKid = widget.kid;
      // Save to local storage for persistence
      AppStateService.saveSelectedKid(widget.kid!);
      _loadStories();
    } else {
      // Try to load from local storage
      _selectedKid = AppStateService.getSelectedKid();
      if (_selectedKid != null) {
        _loadStories();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the selected kid from route arguments if not already set
    if (_selectedKid == null) {
      final kid = ModalRoute.of(context)?.settings.arguments as Kid?;
      if (kid != null) {
        _selectedKid = kid;
        // Save to local storage for persistence
        AppStateService.saveSelectedKid(kid);
        _loadStories();
      }
    }
  }

  Future<void> _loadStories() async {
    if (_selectedKid == null) return;
    
    setState(() {
      _isLoadingStories = true;
    });

    try {
      final stories = await KidService.getStoriesForKid(_selectedKid!.id);
      setState(() {
        _stories = stories;
        // For now, split stories into favourites and latest
        // In the future, you could add favourite marking functionality
        _favouriteStories = stories.take(3).toList();
        _latestStories = stories.take(3).toList();
        _isLoadingStories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onNavTap(int index) {
    // Don't update state immediately - wait for actual navigation
    switch (index) {
      case 0:
        // Profile - navigate to kids profile with slide LEFT (from left to right)
        Navigator.of(context).push(
          SlideFromLeftRoute(page: ProfileScreen(kid: _selectedKid)),
        ).then((_) {
          // Reset navigation index when returning from profile
          setState(() {
            _currentNavIndex = 1;
          });
        });
        break;
      case 1:
        // Home - already on home screen
        setState(() {
          _currentNavIndex = 1;
        });
        break;
      case 2:
        // Create - open upload screen
        _openUploadScreen();
        // Reset navigation index since we don't stay on create tab
        setState(() {
          _currentNavIndex = 1;
        });
        break;
      case 3:
        // Settings - navigate to parent dashboard with slide RIGHT (from right to left)
        Navigator.of(context).push(
          SlideFromRightRoute(page: const PinEntryScreen()),
        ).then((_) {
          // Reset navigation index when returning from settings
          setState(() {
            _currentNavIndex = 1;
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no kid is selected, show error
    if (_selectedKid == null) {
      return Scaffold(
        backgroundColor: AppTheme.whiteScreenBackground,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No profile selected',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/profile-select');
                  },
                  child: Text(
                    'Select Profile',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          // Bottom layer: Yellow background only
          Container(
            color: AppColors.secondary,
            child: Column(
              children: [
                // Header space (header moved to Positioned)
                SizedBox(
                  height: AppTheme.screenHeaderTopPadding + 60, // Space for header
                ),
                // Yellow section content (just spacing, button moved outside)
                SizedBox(
                  height: 120, // Space for mascot and button
                ),
                // Fill remaining space with yellow
                Expanded(
                  child: Container(color: AppColors.secondary),
                ),
              ],
            ),
          ),
          // Middle layer: Cloud and mascot behind white container
          Positioned(
            top: 120, // Higher up in yellow section
            left: _getResponsiveCloudPosition(context), // Responsive positioning
            child: SvgPicture.asset(
              'assets/images/cloud-1.svg',
              width: MediaQuery.of(context).size.width * 1.8, // Larger
              height: MediaQuery.of(context).size.width * 0.9,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Color(0xFFDFBBC6), // EXACT same color as pink cloud in processing screen
                BlendMode.srcIn,
              ),
            ),
          ),
          Positioned(
            top: 180, // Higher up in yellow section
            left: 20, // Moved even further to the left
            child: SvgPicture.asset(
              'assets/images/mascot-body-1.svg',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 210, // Move face lower on mascot body
            left: 90, // Move face to the right to center it (was 85)
            child: SvgPicture.asset(
              'assets/images/face-1.svg', // Changed to face-1 as requested
              width: 40, // Made smaller (was 50)
              height: 20, // Made smaller (was 25)
              fit: BoxFit.contain,
            ),
          ),
          // Top layer: White container covers cloud and mascot
          Positioned(
            top: 260, // Position where white container should start
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, -1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                bottom: true,
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(left: AppTheme.getGlobalPadding(context)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Favourites section
                        _buildStorySection(AppLocalizations.of(context)!.favourites, _favouriteStories),
                        
                        const SizedBox(height: 32),
                        
                        // Latest section
                        _buildStorySection(AppLocalizations.of(context)!.latest, _latestStories),
                        
                        const SizedBox(height: 32),
                        
                        // Kid's stories section
                        _buildStorySection(AppLocalizations.of(context)!.kidStories(_selectedKid!.name), _stories),
                        
                        const SizedBox(height: 100), // Extra space for bottom nav
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Header with title and profile on top of everything
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.getGlobalPadding(context),
                  AppTheme.screenHeaderTopPadding,
                  AppTheme.getGlobalPadding(context),
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.myTales,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile-select');
                      },
                      child: Column(
                        children: [
                          ProfileAvatar(
                            radius: 25,
                            profileType: ProfileAvatar.fromString(_selectedKid?.avatarType ?? 'profile1'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedKid?.name ?? 'Kid',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Create button positioned on top of everything
          Positioned(
            top: 140, // Position it in the yellow section
            right: AppTheme.getGlobalPadding(context),
            child: SafeArea(
              child: FilledButton(
                onPressed: _openUploadScreen,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Reduced horizontal padding
                  minimumSize: const Size(120, 60), // Shorter width, same height
                ),
                child: Text(AppLocalizations.of(context)!.create),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }


  Widget _buildCreateSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton(
        onPressed: _openUploadScreen,
        child: const Text('create'),
      ),
    );
  }

  
  void _openUploadScreen() {
    Navigator.pushNamed(
      context,
      '/upload',
      arguments: {
        'kid': _selectedKid,
      },
    ).then((_) {
      // Refresh stories when returning from upload screen
      _loadStories();
    });
  }

  Widget _buildWhiteSection() {
    if (_isLoadingStories) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return _buildWhiteSectionContent();
  }

  Widget _buildWhiteSectionContent() {
    return Padding(
      padding: EdgeInsets.only(left: AppTheme.getGlobalPadding(context)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Favourites section
          _buildStorySection('Favourites', _favouriteStories),
          
          const SizedBox(height: 32),
          
          // Latest section
          _buildStorySection('Latest', _latestStories),
          
          const SizedBox(height: 32),
          
          // Kid's stories section
          _buildStorySection('${_selectedKid!.name}\'s stories', _stories),
          
          const SizedBox(height: 100), // Extra space for bottom nav
        ],
        ),
      ),
    );
  }

  Widget _buildStorySection(String title, List<Story> stories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        
        const SizedBox(height: 16),
        
        if (stories.isEmpty)
          Container(
            height: 120,
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context)!.noStoriesYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final cardSpacing = ResponsiveBreakpoints.getResponsivePadding(
                  context,
                  mobile: 16.0,
                  tablet: 20.0,
                  desktop: 24.0,
                );
                return Padding(
                  padding: EdgeInsets.only(right: index < stories.length - 1 ? cardSpacing : 0),
                  child: _buildStoryCard(stories[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStoryCard(Story story) {
    return Container(
      width: 140,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: story.status == StoryStatus.approved ? () {
            Navigator.pushNamed(
              context,
              '/story-display',
              arguments: story,
            );
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Story cover image
              Container(
                width: double.infinity,
                height: 120,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: story.status == StoryStatus.pending
                      ? Container(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/images/stories/default-cover.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.lightGrey,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: AppColors.grey,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Story title below image
              Text(
                story.title.isNotEmpty ? story.title : 'New Story',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get responsive cloud position to ensure it looks consistent across screen sizes
  double _getResponsiveCloudPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      // Mobile: position cloud further left, mostly off-screen
      return -200;
    } else if (screenWidth < 1200) {
      // Tablet: move cloud much further left to maintain proportion
      return -500;
    } else {
      // Desktop: move cloud very far left for much larger screens
      return -800;
    }
  }


}