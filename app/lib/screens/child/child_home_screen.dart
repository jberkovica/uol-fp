import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_theme.dart';
import '../../services/kid_service.dart';
import '../../services/app_state_service.dart';
import '../../models/story.dart';
import '../../models/kid.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/input_format.dart';
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
  InputFormat _selectedFormat = InputFormat.image; // Default to image
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
        // Create - open upload screen with selected format
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
      body: CustomScrollView(
              slivers: [
                // Header and yellow section (scrollable)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.secondary,
                    child: Column(
                      children: [
                        // Header with title and profile on same line
                        SafeArea(
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
                                  'My tales',
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
                        // Yellow section content (Create button and icons aligned)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppTheme.getGlobalPadding(context),
                            20, // Less spacing after header
                            AppTheme.getGlobalPadding(context),
                            30, // Less bottom padding to not overlap shadow
                          ),
                          child: _buildCreateSection(),
                        ),
                        
                        // Space for shadow to show
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                // White section with shadow - fills remaining space
                SliverFillRemaining(
                  hasScrollBody: false,
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
                      child: _buildWhiteSectionContent(),
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
    return Column(
      children: [
        // Format toggle icons at top (centered like upload screen)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleIcon(FontAwesomeIcons.image, FontAwesomeIcons.solidImage, InputFormat.image),
            const SizedBox(width: 30),
            _buildToggleIcon(FontAwesomeIcons.microphone, FontAwesomeIcons.microphone, InputFormat.audio),
            const SizedBox(width: 30),
            _buildToggleIcon(FontAwesomeIcons.penToSquare, FontAwesomeIcons.solidPenToSquare, InputFormat.text),
          ],
        ),
        
        const SizedBox(height: 25),
        
        // Create button centered below (violet)
        ElevatedButton(
          onPressed: _openUploadScreen,
          child: const Text('create'),
        ),
      ],
    );
  }

  Widget _buildToggleIcon(IconData regularIcon, IconData solidIcon, InputFormat format) {
    final isSelected = _selectedFormat == format;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: FaIcon(
            isSelected ? solidIcon : regularIcon,
            key: ValueKey(isSelected),
            color: isSelected ? AppColors.primary : Colors.black54,
            size: 20,
          ),
        ),
      ),
    );
  }
  
  void _openUploadScreen() {
    Navigator.pushNamed(
      context,
      '/upload',
      arguments: {
        'format': _selectedFormat,
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
              'No stories yet',
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
                                  FontAwesomeIcons.image,
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


}