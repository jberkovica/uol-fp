import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
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
  
  // Parallax scroll variables
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    
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
          // Layer 1: Yellow background (fills entire screen)
          Container(
            color: AppColors.secondary,
          ),
          
          // Layer 2: Fixed elements on yellow background (cloud, mascot, header, button)
          // Cloud - fixed position
          Positioned(
            top: 120,
            left: _getResponsiveCloudPosition(context),
            child: SvgPicture.asset(
              'assets/images/cloud-1.svg',
              width: MediaQuery.of(context).size.width * 1.8,
              height: MediaQuery.of(context).size.width * 0.9,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Color(0xFFDFBBC6),
                BlendMode.srcIn,
              ),
            ),
          ),
          // Mascot - fixed position
          Positioned(
            top: 180,
            left: 20,
            child: SvgPicture.asset(
              'assets/images/mascot-body-1.svg',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          // Mascot face - fixed position
          Positioned(
            top: 210,
            left: 90,
            child: SvgPicture.asset(
              'assets/images/face-1.svg',
              width: 40,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          
          // Layer 3: Single unified scroll with parallax effect
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollUpdateNotification) {
                // Only handle vertical scrolls, ignore horizontal story card scrolls
                if (notification.metrics.axis == Axis.vertical) {
                  setState(() {
                    _scrollOffset = notification.metrics.pixels;
                  });
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Spacer to push white container down with parallax effect
                  SizedBox(height: (260 + (-_scrollOffset * 0.5)).clamp(160, 260)),
                  
                  // White container with stories
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 160,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        // Only left corner rounded, as per original design
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, -1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: AppTheme.getGlobalPadding(context),
                        top: 24,
                        bottom: 120, // Extra space for bottom nav
                      ),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Layer 4: Clickable elements (on top for clicks)
          // Header with title and profile - moved to top layer
          Positioned(
            top: AppTheme.screenHeaderTopPadding,
            left: AppTheme.getGlobalPadding(context),
            right: AppTheme.getGlobalPadding(context),
            child: SafeArea(
              bottom: false,
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
          
          // Create button - moved to top layer
          Positioned(
            top: 140,
            right: AppTheme.getGlobalPadding(context),
            child: SafeArea(
              child: FilledButton(
                onPressed: _openUploadScreen,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  minimumSize: const Size(120, 60),
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
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/icons/photo.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
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