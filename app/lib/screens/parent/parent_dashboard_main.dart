import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_theme.dart';
import '../../models/kid.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/app_state_service.dart';

class ParentDashboardMain extends StatefulWidget {
  const ParentDashboardMain({super.key});

  @override
  State<ParentDashboardMain> createState() => _ParentDashboardMainState();
}

class _ParentDashboardMainState extends State<ParentDashboardMain> {
  int _currentNavIndex = 2; // Settings tab
  List<Kid> _kids = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKids();
  }

  Future<void> _loadKids() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement getAllKids or use getKidsForUser with actual user ID
      // For now, return empty list
      setState(() {
        _kids = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Profile - navigate back to child profile
        _navigateBackToChildArea('/profile');
        break;
      case 1:
        // Home - navigate back to child home
        _navigateBackToChildArea('/child-home');
        break;
      case 2:
        // Already on parent dashboard
        setState(() {
          _currentNavIndex = 2;
        });
        break;
    }
  }
  
  void _navigateBackToChildArea(String route) {
    // Pop back through the navigation stack to return to the child area
    // This will pop until we reach a non-parent screen
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/child-home'),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const Spacer(),
          Text(
            'Parent Dashboard',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildOverviewSection(),
                  const SizedBox(height: 32),
                  _buildKidsSection(),
                  const SizedBox(height: 32),
                  _buildControlsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    final totalStories = _kids.fold<int>(0, (sum, kid) => sum + 0); // TODO: Count stories
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.child_care,
                value: '${_kids.length}',
                label: 'Kids Profiles',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.auto_stories,
                value: '$totalStories',
                label: 'Total Stories',
                color: AppColors.secondary,
              ),
            ),
          ],
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              'Kids Profiles',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile-select');
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Kid'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
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
          SvgPicture.asset(
            AppAssets.miraReady,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'No Kids Profiles Yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.flatWhiteCard,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.child_care,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          kid.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Avatar: ${kid.avatarType} • Created ${_formatDate(kid.createdAt)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                // TODO: Navigate to edit kid
                break;
              case 'stories':
                // TODO: Navigate to kid's stories
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
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parent Controls',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
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
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: AppColors.textGrey,
        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete ${kid.name}\'s profile? This will also delete all their stories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete kid
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality coming soon!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}