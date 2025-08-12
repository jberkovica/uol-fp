import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/input_format.dart';
import '../../models/kid.dart';
import '../../models/story.dart';
import '../../services/story_cache_service.dart';
import '../../services/app_state_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/avatar_selector_sheet.dart';
import '../../utils/page_transitions.dart';
import '../parent/pin_entry_screen.dart';
import '../../services/kid_service.dart';
import '../../generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final Kid? kid;
  
  const ProfileScreen({super.key, this.kid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentNavIndex = 0; // Profile tab
  Kid? _kid;
  List<Story> _stories = [];
  
  // Parallax scroll variables
  double _scrollOffset = 0.0;
  
  // Real-time story subscription
  StreamSubscription<List<Story>>? _storiesSubscription;

  @override
  void initState() {
    super.initState();
    // Use kid passed from constructor or try to get from route arguments or local storage
    if (widget.kid != null) {
      _kid = widget.kid;
      // Save to local storage for persistence
      AppStateService.saveSelectedKid(widget.kid!);
      _setupStoriesStream();
    } else {
      // Try route arguments or local storage
      _initializeKid();
    }
  }
  
  void _initializeKid() {
    // Try to load from local storage first
    _kid = AppStateService.getSelectedKid();
    if (_kid != null) {
      _setupStoriesStream();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only check route arguments if kid is not already set
    if (_kid == null) {
      final kid = ModalRoute.of(context)?.settings.arguments as Kid?;
      if (kid != null) {
        _kid = kid;
        // Save to local storage for persistence
        AppStateService.saveSelectedKid(kid);
        _setupStoriesStream();
      }
    }
  }

  /// Setup real-time stories stream
  void _setupStoriesStream() {
    if (_kid == null) return;
    
    // Cancel existing subscription
    _storiesSubscription?.cancel();
    
    // Setup new real-time subscription
    _storiesSubscription = StoryCacheService.getStoriesStream(_kid!.id).listen(
      (stories) {
        setState(() {
          _stories = stories;
        });
      },
      onError: (error) {
        // Handle error silently for now
      },
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Already on profile
        setState(() {
          _currentNavIndex = 0;
        });
        break;
      case 1:
        // Home - go back to previous screen (home) with animation
        Navigator.of(context).pop();
        break;
      case 2:
        // Create - navigate to upload screen with default image format
        Navigator.pushNamed(
          context,
          '/upload',
          arguments: {
            'format': InputFormat.image, // Default to image format
            'kid': _kid, // Current kid profile
          },
        ).then((_) {
          // Reset navigation index when returning from upload
          setState(() {
            _currentNavIndex = 0;
          });
          // Real-time subscription will automatically update stories
        });
        break;
      case 3:
        // Settings - navigate to parent dashboard with slide RIGHT (from right to left)
        Navigator.of(context).push(
          SlideFromRightRoute(page: const PinEntryScreen()),
        ).then((_) {
          // Reset navigation index when returning from settings
          setState(() {
            _currentNavIndex = 0;
          });
        });
        break;
    }
  }

  /// Show avatar selector and handle avatar change
  Future<void> _changeAvatar() async {
    if (_kid == null) return;

    final newAvatarType = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarSelectorSheet(
        currentAvatarType: _kid!.avatarType,
        onAvatarSelected: (avatarType) {
          Navigator.of(context).pop(avatarType);
        },
      ),
    );

    if (newAvatarType != null && newAvatarType != _kid!.avatarType) {
      try {
        // Update avatar in backend
        await KidService.updateKid(
          kidId: _kid!.id,
          name: _kid!.name,
          age: _kid!.age,
          gender: _kid!.gender,
          avatarType: newAvatarType,
          appearanceMethod: _kid!.appearanceMethod,
          appearanceDescription: _kid!.appearanceDescription,
          favoriteGenres: _kid!.favoriteGenres,
          parentNotes: _kid!.parentNotes,
          preferredLanguage: _kid!.preferredLanguage,
        );

        // Update local state
        setState(() {
          _kid = _kid!.copyWith(avatarType: newAvatarType);
        });

        // Save updated kid to local storage
        AppStateService.saveSelectedKid(_kid!);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.avatarUpdatedSuccessfully ?? 'Avatar updated successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.failedToUpdateAvatar ?? 'Failed to update avatar. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _storiesSubscription?.cancel();
    if (_kid != null) {
      StoryCacheService.dispose(_kid!.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_kid == null) {
      return Scaffold(
        backgroundColor: AppTheme.whiteScreenBackground,
        body: SafeArea(
          child: Center(
            child: Text(AppLocalizations.of(context)!.noProfileSelected),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.yellowScreenBackground,
      body: Stack(
        children: [
          // Layer 1: Yellow background (fills entire screen)
          Container(
            color: AppTheme.yellowScreenBackground,
          ),
          
          // Layer 2: Fixed profile header (stays under white container)
          SafeArea(
            child: _buildProfileHeader(),
          ),
          
          // Layer 3: Scrollable white content with parallax effect
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollUpdateNotification) {
                  // Only handle vertical scrolls
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
                    SizedBox(height: (240 + (-_scrollOffset * 0.5)).clamp(150, 240)),
                    
                    // White content container
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ),
          
          // Layer 4: Only the back button (on top for clicks)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: SvgPicture.asset(
                'assets/icons/arrow-right.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
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

  Widget _buildProfileHeader() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Back button in corner - no padding
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: SvgPicture.asset(
                'assets/icons/arrow-right.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
              ),
            ),
          ),
          // Profile content with global padding
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.getGlobalPadding(context),
              AppTheme.screenHeaderTopPadding,
              AppTheme.getGlobalPadding(context),
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile avatar - tappable to change
                Center(
                  child: GestureDetector(
                    onTap: _changeAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ProfileAvatar(
                        radius: 60,
                        profileType: _getProfileTypeFromString(_kid!.avatarType),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Kid's name
                Center(
                  child: Text(
                    _kid!.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildContent() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 200,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.getGlobalPadding(context), // Left padding
          40, // Fixed top padding
          AppTheme.getGlobalPadding(context), // Right padding
          120, // Extra bottom padding for nav
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _buildSimpleStats(),
                const SizedBox(height: 60), // More space after stats
                _buildOptionsSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildSimpleStats() {
    final totalWords = _stories.fold<int>(0, (sum, story) => sum + story.content.split(' ').length);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSimpleStat(
          icon: 'assets/icons/book.svg',
          value: '${_stories.length}',
          label: AppLocalizations.of(context)!.storiesCreated,
          color: AppColors.primary,
        ),
        _buildSimpleStat(
          icon: 'assets/icons/pencil-plus.svg',
          value: '$totalWords',
          label: AppLocalizations.of(context)!.wordsWritten,
          color: AppColors.orange,
        ),
      ],
    );
  }

  Widget _buildSimpleStat({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        SvgPicture.asset(
          icon,
          width: 32,
          height: 32,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }


  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.profileOptions,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: AppTheme.flatWhiteCard,
          child: Column(
            children: [
              _buildOptionTile(
                icon: 'assets/icons/pencil-plus.svg',
                title: AppLocalizations.of(context)!.editProfile,
                subtitle: AppLocalizations.of(context)!.changeNameAgeAvatar,
                onTap: () {
                  // TODO: Navigate to edit profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.editProfileComingSoon)),
                  );
                },
              ),
              _buildOptionTile(
                icon: 'assets/icons/user.svg',
                title: AppLocalizations.of(context)!.switchProfile,
                subtitle: AppLocalizations.of(context)!.changeToDifferentProfile,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/profile-select');
                },
              ),
              _buildOptionTile(
                icon: 'assets/icons/heart.svg',
                title: AppLocalizations.of(context)!.favoriteStories,
                subtitle: AppLocalizations.of(context)!.viewYourMostLovedTales,
                onTap: () {
                  // TODO: Navigate to favorites
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.favoritesComingSoon)),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: SvgPicture.asset(
        icon,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      trailing: SvgPicture.asset(
        'assets/icons/arrow-right.svg',
        width: 16,
        height: 16,
        colorFilter: const ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
      ),
      onTap: onTap,
    );
  }


  ProfileType _getProfileTypeFromString(String avatarType) {
    switch (avatarType) {
      case 'profile1':
        return ProfileType.profile1;
      case 'profile2':
        return ProfileType.profile2;
      case 'profile3':
        return ProfileType.profile3;
      case 'profile4':
        return ProfileType.profile4;
      default:
        return ProfileType.profile1;
    }
  }
}