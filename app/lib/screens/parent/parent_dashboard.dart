import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../constants/kid_profile_constants.dart';
import '../../models/input_format.dart';
import '../../models/kid.dart';
import '../../models/story.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../services/app_state_service.dart';
import '../../services/kid_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/ai_story_service.dart';
import 'kid_profile_edit_screen.dart';
import '../../services/logging_service.dart';
import '../../utils/page_transitions.dart';
import '../child/profile_screen.dart';
import '../../generated/app_localizations.dart';

class ParentDashboardMain extends StatefulWidget {
  const ParentDashboardMain({super.key});

  @override
  State<ParentDashboardMain> createState() => _ParentDashboardMainState();
}

class _ParentDashboardMainState extends State<ParentDashboardMain> {
  static final _logger = LoggingService.getLogger('ParentDashboard');
  int _currentNavIndex = 3; // Settings tab (moved from 2 to 3)
  List<Kid> _kids = [];
  Map<String, List<Story>> _kidStories = {};
  List<Story> _pendingStories = [];
  bool _isLoading = false;
  bool _isLoadingPendingStories = false;
  String? _currentUserId;
  String _currentApprovalMode = 'auto'; // Default to auto-approve
  
  // Parallax scroll variables  
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // Get current user ID from auth service or use placeholder
    final authUser = AuthService.instance.currentUser;
    _currentUserId = authUser?.id ?? 'placeholder-user-id';
    await _loadApprovalMode();
    await _loadKids();
    await _loadPendingStories();
  }

  Future<void> _loadKids() async {
    if (_currentUserId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all kids for the current user
      final kids = await KidService.getKidsForUser(_currentUserId!);
      
      // Load stories for each kid
      final Map<String, List<Story>> storiesMap = {};
      for (final kid in kids) {
        try {
          final stories = await KidService.getStoriesForKid(kid.id);
          storiesMap[kid.id] = stories;
        } catch (e) {
          _logger.e('Error loading stories for kid', error: e);
          storiesMap[kid.id] = [];
        }
      }
      
      setState(() {
        _kids = kids;
        _kidStories = storiesMap;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading kids', error: e);
      setState(() {
        _kids = [];
        _kidStories = {};
        _isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToLoadKids(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadPendingStories() async {
    setState(() {
      _isLoadingPendingStories = true;
    });

    try {
      final pendingStories = await AIStoryService().getPendingStories();
      
      setState(() {
        _pendingStories = pendingStories;
        _isLoadingPendingStories = false;
      });
    } catch (e) {
      _logger.e('Error loading pending stories', error: e);
      setState(() {
        _pendingStories = [];
        _isLoadingPendingStories = false;
      });
    }
  }

  Future<void> _loadApprovalMode() async {
    try {
      final approvalMode = AuthService.instance.getUserApprovalMode();
      setState(() {
        _currentApprovalMode = approvalMode;
      });
    } catch (e) {
      _logger.e('Error loading approval mode', error: e);
      // Keep default 'auto' if there's an error
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Profile - navigate to selected kid's profile (if any)
        _navigateToKidProfile();
        break;
      case 1:
        // Home - pop back to reveal home underneath (parent dashboard slides away)
        Navigator.of(context).pop();
        break;
      case 2:
        // Create - navigate to upload screen for selected kid
        _navigateToCreateStory();
        break;
      case 3:
        // Already on parent dashboard (Settings)
        setState(() {
          _currentNavIndex = 3;
        });
        break;
    }
  }
  
  void _navigateToCreateStory() {
    // Get the last selected kid from local storage
    final selectedKid = AppStateService.getSelectedKid();
    
    if (selectedKid != null) {
      // Navigate to upload screen for creating a story
      Navigator.pushNamed(
        context,
        '/upload',
        arguments: {
          'format': InputFormat.image, // Default to image format
          'kid': selectedKid, // Selected kid profile
        },
      ).then((_) {
        // Reset navigation index when returning from upload
        setState(() {
          _currentNavIndex = 3;
        });
        // Refresh stories after creating new one
        _loadKids();
      });
    } else if (_kids.isNotEmpty) {
      // If no specific kid selected, use first available kid
      final firstKid = _kids.first;
      Navigator.pushNamed(
        context,
        '/upload',
        arguments: {
          'format': InputFormat.image, // Default to image format
          'kid': firstKid, // First available kid
        },
      ).then((_) {
        // Reset navigation index when returning from upload
        setState(() {
          _currentNavIndex = 3;
        });
        // Refresh stories after creating new one
        _loadKids();
      });
    } else {
      // No kids available - show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addKidProfileFirst),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToKidProfile() {
    // Get the last selected kid from local storage
    final selectedKid = AppStateService.getSelectedKid();
    
    if (selectedKid != null) {
      // Replace parent dashboard with kid's profile (go back to child area)
      Navigator.of(context).pushReplacement(
        SlideFromLeftRoute(page: ProfileScreen(kid: selectedKid)),
      );
    } else if (_kids.isNotEmpty) {
      // If no selected kid but we have kids, use the first one
      Navigator.of(context).pushReplacement(
        SlideFromLeftRoute(page: ProfileScreen(kid: _kids.first)),
      );
    } else {
      // No kids available - show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noKidsProfilesAvailable),
          backgroundColor: AppColors.grey,
        ),
      );
    }
  }
  
  void _navigateBackToChildArea() {
    // Pop back through the navigation stack to return to the child area
    Navigator.of(context).popUntil((route) => 
      route.settings.name != '/parent-dashboard-main' && 
      route.settings.name != '/parent-dashboard'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Layer 1: Purple background (fills entire screen)
          Container(
            color: AppColors.primary,
          ),
          
          // Layer 2: Fixed header content (stays under white container)
          SafeArea(
            child: _buildHeader(),
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
                    SizedBox(height: (140 + (-_scrollOffset * 0.5)).clamp(80, 140)),
                    
                    // White content container
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ),
          
          // Layer 4: Back button (on top for clicks)
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: ResponsiveBreakpoints.getResponsivePadding(context),
                top: 20,
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: SvgPicture.asset(
                  'assets/icons/arrow-left.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                ),
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

  Widget _buildHeader() {
    final horizontalPadding = ResponsiveBreakpoints.getResponsivePadding(context);
    
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: EdgeInsets.fromLTRB(horizontalPadding, 60, horizontalPadding, 40),
        child: Column(
        children: [
          
          // Title
          Text(
            AppLocalizations.of(context)!.parentDashboard,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 250,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.whiteScreenBackground,
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
      child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
                constraints: const BoxConstraints(maxWidth: 1200),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadKids();
                    await _loadPendingStories();
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.getGlobalPadding(context),
                      AppTheme.getGlobalPadding(context),
                      AppTheme.getGlobalPadding(context),
                      80, // Extra bottom padding for nav
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildPendingStoriesSection(),
                        const SizedBox(height: 32),
                        _buildKidsSection(),
                        const SizedBox(height: 32),
                        _buildControlsSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }


  Widget _buildKidsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.kidsProfiles,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile-select');
              },
              icon: SvgPicture.asset(
                'assets/icons/plus.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              label: Text(AppLocalizations.of(context)!.addKid),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (_kids.isEmpty)
          _buildEmptyKidsState()
        else
          ..._kids.map((kid) => _buildKidCard(kid)),
      ],
    );
  }

  Widget _buildEmptyKidsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.flatWhiteCard,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.noKidsProfilesYet,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addFirstKidProfile,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKidCard(Kid kid) {
    final storyCount = _kidStories[kid.id]?.length ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.flatWhiteCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Avatar
            ProfileAvatar(
              radius: 28,
              profileType: _getProfileTypeFromString(kid.avatarType),
            ),
            const SizedBox(width: 16),
            
            // Kid Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kid.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.stories(storyCount),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.createdDate(_formatDate(kid.createdAt)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Inline Action Icons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Profile Button (moved to first position)
                IconButton(
                  onPressed: () => _navigateToEditScreen(kid),
                  icon: SvgPicture.asset(
                    'assets/icons/mood-edit.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                  ),
                  tooltip: 'Edit Profile',
                ),
                
                // View Stories Button (moved to second position)
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.viewStories)),
                    );
                  },
                  icon: SvgPicture.asset(
                    'assets/icons/file-pencil.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn),
                  ),
                  tooltip: 'View Stories',
                ),
                
                // Delete Profile Button
                IconButton(
                  onPressed: () => _showDeleteKidDialog(kid),
                  icon: SvgPicture.asset(
                    'assets/icons/trash.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.error, BlendMode.srcIn),
                  ),
                  tooltip: 'Delete Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.parentControls,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        
        Container(
          decoration: AppTheme.flatWhiteCard,
          child: Column(
            children: [
              _buildControlTile(
                icon: 'assets/icons/world.svg',
                title: AppLocalizations.of(context)!.language,
                subtitle: _getLanguageDisplayName(LanguageService.instance.currentLocale.languageCode),
                onTap: _showLanguageSelector,
              ),
              _buildControlTile(
                icon: 'assets/icons/shield-check.svg',
                title: AppLocalizations.of(context)!.approvalMethod,
                subtitle: _getApprovalModeDisplayName(_currentApprovalMode),
                onTap: _showApprovalModeSelector,
              ),
              _buildControlTile(
                icon: 'assets/icons/shield-lock.svg',
                title: AppLocalizations.of(context)!.changePin,
                subtitle: AppLocalizations.of(context)!.updateParentDashboardPin,
                onTap: () {
                  Navigator.pushNamed(context, '/change-pin');
                },
              ),
              _buildControlTile(
                icon: 'assets/icons/adjustments-horizontal.svg',
                title: AppLocalizations.of(context)!.storySettings,
                subtitle: AppLocalizations.of(context)!.configureStoryGenerationPreferences,
                onTap: () {
                  // TODO: Navigate to story settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.storySettingsComingSoon)),
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Logout button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await AuthService.instance.signOut();
                if (mounted) {
                  // Use a more efficient navigation approach
                  while (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to logout: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            icon: SvgPicture.asset(
              'assets/icons/logout.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.error, BlendMode.srcIn),
            ),
            label: Text(
              AppLocalizations.of(context)!.logout,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.pendingStories,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            if (_pendingStories.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pendingStories.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (_isLoadingPendingStories)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.flatWhiteCard,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_pendingStories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.flatWhiteCard,
            child: Text(
              AppLocalizations.of(context)!.noPendingStories,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.mediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._pendingStories.map((story) => _buildPendingStoryCard(story)),
      ],
    );
  }

  Widget _buildPendingStoryCard(Story story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.flatWhiteCard,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Story icon with pending indicator
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 51),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/book.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Story info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (story.childName != null)
                    Text(
                      AppLocalizations.of(context)!.forChild(story.childName!),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(story.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Review button
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/story-preview',
                  arguments: story,
                );
                
                // Refresh pending stories if story was reviewed
                if (result == true) {
                  await _loadPendingStories();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.review,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTile({
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
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
      ),
      onTap: onTap,
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(ResponsiveBreakpoints.getResponsivePadding(context)),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/arrow-left.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.error, BlendMode.srcIn),
              ),
              title: Text(AppLocalizations.of(context)!.exitParentMode),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/child-home');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditScreen(Kid kid) async {
    final result = await Navigator.of(context).push<Kid>(
      MaterialPageRoute(
        builder: (context) => KidProfileEditScreen(kid: kid),
      ),
    );

    if (result != null) {
      // Optimistically update the kid in our local list
      setState(() {
        final index = _kids.indexWhere((k) => k.id == kid.id);
        if (index != -1) {
          _kids[index] = result;
        }
      });
      
      // Clear service cache to ensure fresh data on next load
      KidService.clearCache();
    }
  }


  void _showDeleteKidDialog(Kid kid) {
    final storyCount = _kidStories[kid.id]?.length ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(AppLocalizations.of(context)!.deleteProfile),
        content: Text(
          AppLocalizations.of(context)!.deleteProfileConfirm(kid.name, storyCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => _deleteKid(kid),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteKid(Kid kid) async {
    Navigator.pop(context); // Close dialog
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.deletingKidProfile(kid.name)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await KidService.deleteKid(kid.id);
      
      // Refresh the kids list
      await _loadKids();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.kidProfileDeleted(kid.name)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToDeleteProfile(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return AppLocalizations.of(context)!.english;
      case 'ru':
        return AppLocalizations.of(context)!.russian;
      case 'lv':
        return AppLocalizations.of(context)!.latvian;
      default:
        return AppLocalizations.of(context)!.english;
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(ResponsiveBreakpoints.getResponsivePadding(context)),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildLanguageOption('en', AppLocalizations.of(context)!.english, '🇺🇸'),
            _buildLanguageOption('ru', AppLocalizations.of(context)!.russian, '🇷🇺'),
            _buildLanguageOption('lv', AppLocalizations.of(context)!.latvian, '🇱🇻'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String languageCode, String languageName, String flag) {
    final isSelected = LanguageService.instance.currentLocale.languageCode == languageCode;
    
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        languageName,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
        ? SvgPicture.asset(
            'assets/icons/circle-dashed-check.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          )
        : null,
      onTap: () async {
        Navigator.pop(context);
        await _updateLanguage(languageCode);
      },
    );
  }

  Future<void> _updateLanguage(String languageCode) async {
    try {
      final success = await LanguageService.instance.updateLanguage(languageCode);
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.languageUpdatedTo(_getLanguageDisplayName(languageCode))),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '✕',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        
        // UI will update automatically via LanguageService listeners
        setState(() {});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUpdateLanguage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingLanguage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getApprovalModeDisplayName(String approvalMode) {
    switch (approvalMode) {
      case 'auto':
        return AppLocalizations.of(context)!.autoApprove;
      case 'app':
        return AppLocalizations.of(context)!.reviewInApp;
      case 'email':
        return AppLocalizations.of(context)!.reviewByEmail;
      default:
        return AppLocalizations.of(context)!.autoApprove;
    }
  }

  void _showApprovalModeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.selectApprovalMethod,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildApprovalModeOption('auto', AppLocalizations.of(context)!.autoApprove, 
                AppLocalizations.of(context)!.autoApproveDescription),
            _buildApprovalModeOption('app', AppLocalizations.of(context)!.reviewInApp,
                AppLocalizations.of(context)!.reviewInAppDescription),
            _buildApprovalModeOption('email', AppLocalizations.of(context)!.reviewByEmail,
                AppLocalizations.of(context)!.reviewByEmailDescription),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalModeOption(String modeCode, String modeName, String description) {
    final isSelected = _currentApprovalMode == modeCode;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        modeName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textDark,
        ),
      ),
      subtitle: Text(
        description,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textGrey,
        ),
      ),
      trailing: isSelected 
        ? SvgPicture.asset(
            'assets/icons/circle-dashed-check.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          )
        : null,
      onTap: () async {
        Navigator.pop(context);
        await _updateApprovalMode(modeCode);
      },
    );
  }

  Future<void> _updateApprovalMode(String approvalMode) async {
    try {
      final success = await AuthService.instance.updateUserApprovalMode(approvalMode);
      
      if (success && mounted) {
        setState(() {
          _currentApprovalMode = approvalMode;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.approvalMethodUpdated(_getApprovalModeDisplayName(approvalMode))),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '✕',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        
        // Reload pending stories since approval mode affects what shows up
        await _loadPendingStories();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUpdateApprovalMethod),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingApprovalMethod(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}