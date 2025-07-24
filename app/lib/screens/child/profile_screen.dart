import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/input_format.dart';
import '../../models/kid.dart';
import '../../models/story.dart';
import '../../services/kid_service.dart';
import '../../services/app_state_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/page_transitions.dart';
import '../parent/pin_entry_screen.dart';
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

  @override
  void initState() {
    super.initState();
    // Use kid passed from constructor or try to get from route arguments or local storage
    if (widget.kid != null) {
      _kid = widget.kid;
      // Save to local storage for persistence
      AppStateService.saveSelectedKid(widget.kid!);
      _loadStories();
    } else {
      // Try route arguments or local storage
      _initializeKid();
    }
  }
  
  void _initializeKid() {
    // Try to load from local storage first
    _kid = AppStateService.getSelectedKid();
    if (_kid != null) {
      _loadStories();
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
        _loadStories();
      }
    }
  }

  Future<void> _loadStories() async {
    if (_kid == null) return;

    try {
      final stories = await KidService.getStoriesForKid(_kid!.id);
      setState(() {
        _stories = stories;
      });
    } catch (e) {
      // Handle error silently for now
    }
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
          // Refresh stories after creating new one
          _loadStories();
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
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: AppTheme.yellowScreenBackground,
      child: Stack(
        children: [
          // Back button in corner - no padding
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textDark,
                size: 28,
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
                // Profile avatar
                Center(
                  child: ProfileAvatar(
                    radius: 60,
                    profileType: _getProfileTypeFromString(_kid!.avatarType),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const Spacer(),
          Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            AppTheme.getGlobalPadding(context), // Left padding
            40, // Fixed top padding
            AppTheme.getGlobalPadding(context), // Right padding
            40, // Fixed bottom padding
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
      ),
    );
  }

  Widget _buildProfileInfo() {
    return const SizedBox.shrink(); // Remove profile info section
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.flatWhiteCard.copyWith(
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: ProfileAvatar(
              radius: 40,
              profileType: _getProfileTypeFromString(_kid!.avatarType),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            _kid!.name,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          
          // Avatar type info
          Text(
            AppLocalizations.of(context)!.profileDetails(_kid!.avatarType),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Join date
          Text(
            AppLocalizations.of(context)!.creatingStoriesSince(_formatDate(_kid!.createdAt)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final completedStories = _stories.length;
    final totalWords = _stories.fold<int>(0, (sum, story) => sum + story.content.split(' ').length);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.book_outlined,
            value: '$completedStories',
            label: AppLocalizations.of(context)!.storiesCreated,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: ResponsiveBreakpoints.getResponsivePadding(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        )),
        Expanded(
          child: _buildStatCard(
            icon: Icons.edit_outlined,
            value: '$totalWords',
            label: AppLocalizations.of(context)!.wordsWritten,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStats() {
    final totalWords = _stories.fold<int>(0, (sum, story) => sum + story.content.split(' ').length);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSimpleStat(
          icon: LucideIcons.bookOpen,
          value: '${_stories.length}',
          label: AppLocalizations.of(context)!.storiesCreated,
          color: AppColors.primary,
        ),
        _buildSimpleStat(
          icon: LucideIcons.penTool,
          value: '$totalWords',
          label: AppLocalizations.of(context)!.wordsWritten,
          color: AppColors.orange,
        ),
      ],
    );
  }

  Widget _buildSimpleStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.flatWhiteCard,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.profileOptions,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: AppTheme.flatWhiteCard,
          child: Column(
            children: [
              _buildOptionTile(
                icon: Icons.edit,
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
                icon: Icons.switch_account,
                title: AppLocalizations.of(context)!.switchProfile,
                subtitle: AppLocalizations.of(context)!.changeToDifferentProfile,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/profile-select');
                },
              ),
              _buildOptionTile(
                icon: Icons.favorite,
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
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppColors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
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