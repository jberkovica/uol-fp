import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_theme.dart';
import '../../services/ai_story_service.dart';
import '../../services/kid_service.dart';
import '../../services/app_state_service.dart';
import '../../models/story.dart';
import '../../models/kid.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../utils/page_transitions.dart';
import '../child/profile_screen.dart';
import '../parent/pin_entry_screen.dart';

// Custom clipper for white bottom section with only top-left corner rounded
class RoundedTopLeftClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Line up to rounded corner start
    path.lineTo(0, 24); // 24px from top for rounded corner
    
    // Create rounded top-left corner
    path.quadraticBezierTo(0, 0, 24, 0);
    
    // Line to top right
    path.lineTo(size.width, 0);
    
    // Line to bottom right
    path.lineTo(size.width, size.height);
    
    // Close the path back to bottom left
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ChildHomeScreen extends StatefulWidget {
  final Kid? kid;
  
  const ChildHomeScreen({super.key, this.kid});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final AIStoryService _aiService = AIStoryService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  Kid? _selectedKid;
  List<Story> _stories = [];
  List<Story> _favouriteStories = [];
  List<Story> _latestStories = [];
  bool _isLoadingStories = false;
  int _currentNavIndex = 1; // Home tab is default (middle)

  @override
  void initState() {
    super.initState();
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
            backgroundColor: Colors.red,
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
      backgroundColor: AppColors.secondary, // Yellow background
      body: SafeArea(
        child: _isProcessing
            ? _buildProcessingView()
            : Stack(
                children: [
                  // Yellow background section
                  _buildYellowSection(),
                  
                  // White curved bottom section
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipPath(
                      clipper: RoundedTopLeftClipper(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.65,
                        color: Colors.white,
                        child: _buildWhiteSection(),
                      ),
                    ),
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

  Widget _buildProcessingView() {
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAssets.miraReady,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Creating your magical story...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This may take a few moments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYellowSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and profile avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My tales',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                children: [
                  ProfileAvatar(
                    radius: 24,
                    profileType: ProfileAvatar.fromString(_selectedKid!.avatarType),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedKid!.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Action buttons row
          Row(
            children: [
              // Create button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showImageSourceOptions(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        'Create',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Action icons
              _buildActionIcon(Icons.image, () => _pickImage(ImageSource.gallery)),
              const SizedBox(width: 16),
              _buildActionIcon(Icons.mic, () {
                // TODO: Voice recording functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice recording coming soon!')),
                );
              }),
              const SizedBox(width: 16),
              _buildActionIcon(Icons.menu, () {
                // TODO: More options menu
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            color: AppColors.textDark,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteSection() {
    if (_isLoadingStories) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
    );
  }

  Widget _buildStorySection(String title, List<Story> stories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
                return Padding(
                  padding: EdgeInsets.only(right: index < stories.length - 1 ? 16 : 0),
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

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                'Select Image Source',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 24),

              // Camera option
              _buildSourceButton(
                icon: Icons.camera_alt,
                label: 'Take Photo',
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              const SizedBox(height: 16),

              // Gallery option
              _buildSourceButton(
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 16),

              // Cancel button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGrey,
                  foregroundColor: AppColors.textGrey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isProcessing = true;
        });

        // Generate story using the AI service (pass XFile directly)
        await _generateStory(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateStory(XFile imageFile) async {
    try {
      // Use the selected kid's ID for story generation
      if (_selectedKid == null) {
        throw Exception('No kid profile selected');
      }

      // Generate story using AI service with kid ID
      final Story story =
          await _aiService.generateStoryFromImageFile(imageFile, _selectedKid!.id);

      setState(() {
        _isProcessing = false;
      });

      // Refresh stories list to show the new story
      await _loadStories();

      // Navigate to story display/playback screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/story-display',
          arguments: story,
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate story: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}