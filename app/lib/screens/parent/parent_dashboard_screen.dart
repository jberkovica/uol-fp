import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/story.dart';
import '../../services/mock_story_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storyService = MockStoryService();
  
  // Lists to hold stories
  List<Story> _pendingStories = [];
  List<Story> _approvedStories = [];
  
  // Loading states
  bool _isLoadingPending = true;
  bool _isLoadingApproved = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load stories from our mock service
    _loadPendingStories();
    _loadApprovedStories();
  }
  
  // Load pending stories from the mock service
  Future<void> _loadPendingStories() async {
    setState(() {
      _isLoadingPending = true;
    });
    
    try {
      final stories = await _storyService.getPendingStories();
      if (!mounted) return;
      setState(() {
        _pendingStories = stories;
        _isLoadingPending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPending = false;
      });
      // In a real app, show error message
    }
  }
  
  // Load approved stories from the mock service
  Future<void> _loadApprovedStories() async {
    setState(() {
      _isLoadingApproved = true;
    });
    
    try {
      final stories = await _storyService.getApprovedStories();
      if (!mounted) return;
      setState(() {
        _approvedStories = stories;
        _isLoadingApproved = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingApproved = false;
      });
      // In a real app, show error message
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingReviewsTab(),
                _buildApprovedStoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.lightGrey,
                radius: 30,
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parent',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/profile-select');
                },
                color: AppColors.textDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: AppColors.primary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textDark,
        tabs: const [
          Tab(text: 'Pending Review'),
          Tab(text: 'Approved Stories'),
        ],
      ),
    );
  }

  Widget _buildPendingReviewsTab() {
    // Show loading indicator while data is being fetched
    if (_isLoadingPending) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Show empty state if no pending stories
    if (_pendingStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No stories pending review',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'When children create stories, you\'ll review them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Generate a new mock story for testing
                _storyService.generateStoryFromImage('Lea')
                  .then((story) {
                    if (!mounted) return;
                    _loadPendingStories();
                  });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 179),
              ),
              child: const Text('Generate Test Story'),
            ),
          ],
        ),
      );
    }
    
    // Show list of pending stories
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingStories.length,
      itemBuilder: (context, index) {
        return _buildStoryReviewCard(_pendingStories[index]);
      },
    );
  }

  Widget _buildStoryReviewCard(Story story) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Story image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 40, color: AppColors.grey),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'From: ${story.childName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.backgroundYellow.withValues(alpha: 204),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${story.createdAt.toReadableString()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark.withValues(alpha: 128),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Story content preview
            Text(
              story.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showStoryPreview(context, story);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Approve story logic
                      _showApprovalDialog(context, story);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedStoriesTab() {
    // Show loading indicator while data is being fetched
    if (_isLoadingApproved) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Show empty state if no approved stories
    if (_approvedStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No approved stories yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Approved stories will appear here',
              style: TextStyle(
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    // Show list of approved stories
    return RefreshIndicator(
      onRefresh: _loadApprovedStories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _approvedStories.length,
        itemBuilder: (context, index) {
          return _buildApprovedStoryCard(_approvedStories[index]);
        },
      ),
    );
  }

  Widget _buildApprovedStoryCard(Story story) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Story image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: story.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(story.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: story.imageUrl == null ? AppColors.lightGrey : null,
              ),
              child: story.imageUrl == null
                  ? const Icon(Icons.image, color: AppColors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            // Story details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${story.childName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary.withValues(alpha: 200),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.createdAt.toReadableString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.black.withValues(alpha: 150),
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.play_circle_filled),
              color: AppColors.primary,
              onPressed: () {
                // Navigate to story display screen
                Navigator.pushNamed(
                  context, 
                  '/story-display',
                  arguments: story,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryPreview(BuildContext context, [Story? story]) {
    Navigator.pushNamed(context, '/story-preview', arguments: story);
  }
  
  void _showApprovalDialog(BuildContext context, Story story) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Story?'),
          content: const Text(
            'Once approved, this story will be available to the child.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Approve the story
                _storyService.approveStory(story.id).then((_) {
                  if (!mounted) return;
                  
                  // Refresh both tabs
                  _loadPendingStories();
                  _loadApprovedStories();
                  
                  // Show success feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Story approved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }
}
