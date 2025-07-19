import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/kid.dart';
import '../../models/story.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../services/app_state_service.dart';
import '../../services/kid_service.dart';
import '../../services/auth_service.dart';
import '../../utils/page_transitions.dart';
import '../child/profile_screen.dart';
import '../child/child_home_screen.dart';

class ParentDashboardMain extends StatefulWidget {
  const ParentDashboardMain({super.key});

  @override
  State<ParentDashboardMain> createState() => _ParentDashboardMainState();
}

class _ParentDashboardMainState extends State<ParentDashboardMain> {
  int _currentNavIndex = 2; // Settings tab
  List<Kid> _kids = [];
  Map<String, List<Story>> _kidStories = {};
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // Get current user ID from auth service or use placeholder
    final authUser = AuthService.instance.currentUser;
    _currentUserId = authUser?.id ?? 'placeholder-user-id';
    await _loadKids();
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
          print('Error loading stories for kid ${kid.id}: $e');
          storiesMap[kid.id] = [];
        }
      }
      
      setState(() {
        _kids = kids;
        _kidStories = storiesMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading kids: $e');
      setState(() {
        _kids = [];
        _kidStories = {};
        _isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load kids: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        // Already on parent dashboard
        setState(() {
          _currentNavIndex = 2;
        });
        break;
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
        const SnackBar(
          content: Text('No kids profiles available. Add a kid first!'),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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

  Widget _buildHeader() {
    final totalStories = _kidStories.values.fold<int>(0, (sum, stories) => sum + stories.length);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          // Top row with back button and menu
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showSettingsMenu,
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Title
          Text(
            'Parent Dashboard',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Overview Stats on Purple Background
          Row(
            children: [
              Expanded(
                child: _buildHeaderStatCard(
                  value: '${_kids.length}',
                  label: 'Kids Profiles',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildHeaderStatCard(
                  value: '$totalStories',
                  label: 'Total Stories',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.whiteScreenBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadKids,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildKidsSection(),
                    const SizedBox(height: 32),
                    _buildControlsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderStatCard({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Widget _buildKidsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kids Profiles',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile-select');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Kid'),
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
            'No Kids Profiles Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first kid profile to get started with personalized stories!',
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.flatWhiteCard,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    '$storyCount ${storyCount == 1 ? 'story' : 'stories'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Created ${_formatDate(kid.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Menu Button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textGrey,
                size: 20,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile coming soon!')),
                    );
                    break;
                  case 'stories':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View stories coming soon!')),
                    );
                    break;
                  case 'delete':
                    _showDeleteKidDialog(kid);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Profile'),
                ),
                const PopupMenuItem(
                  value: 'stories',
                  child: Text('View Stories'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Profile'),
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
          'Parent Controls',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        
        Container(
          decoration: AppTheme.flatWhiteCard,
          child: Column(
            children: [
              _buildControlTile(
                icon: Icons.security,
                title: 'Change PIN',
                subtitle: 'Update your parent dashboard PIN',
                onTap: () {
                  // TODO: Navigate to change PIN
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change PIN coming soon!')),
                  );
                },
              ),
              _buildControlTile(
                icon: Icons.tune,
                title: 'Story Settings',
                subtitle: 'Configure story generation preferences',
                onTap: () {
                  // TODO: Navigate to story settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story settings coming soon!')),
                  );
                },
              ),
              _buildControlTile(
                icon: Icons.download,
                title: 'Export Data',
                subtitle: 'Download all stories and data',
                onTap: () {
                  // TODO: Export functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export data coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlTile({
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

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Exit Parent Mode'),
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

  void _showDeleteKidDialog(Kid kid) {
    final storyCount = _kidStories[kid.id]?.length ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete ${kid.name}\'s profile? This will also delete all their $storyCount stories.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteKid(kid),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
        content: Text('Deleting ${kid.name}\'s profile...'),
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
            content: Text('${kid.name}\'s profile deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete profile: $e'),
            backgroundColor: Colors.red,
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
}