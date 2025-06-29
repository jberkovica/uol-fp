import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_theme.dart';
import '../../services/ai_story_service.dart';
import '../../services/kid_service.dart';
import '../../models/story.dart';
import '../../models/kid.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final AIStoryService _aiService = AIStoryService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  Kid? _selectedKid;
  List<Story> _stories = [];
  bool _isLoadingStories = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the selected kid from route arguments
    if (_selectedKid == null) {
      final kid = ModalRoute.of(context)?.settings.arguments as Kid?;
      if (kid != null) {
        _selectedKid = kid;
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

  @override
  Widget build(BuildContext context) {
    // If no kid is selected, show error
    if (_selectedKid == null) {
      return Scaffold(
        backgroundColor: AppTheme.yellowScreenBackground,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No profile selected',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/profile-select');
                  },
                  child: Text(
                    'Select Profile',
                    style: GoogleFonts.manrope(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _stories.isNotEmpty ? AppTheme.whiteScreenBackground : AppTheme.yellowScreenBackground,
      body: SafeArea(
        child: _isProcessing
            ? _buildProcessingView()
            : Column(
                children: [
                  _buildHeader('${_selectedKid!.name}\'s tales'),
                  Expanded(
                    child: _buildContent(context),
                  ),
                  _buildFooter(context),
                ],
              ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
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
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This may take a few moments',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoadingStories) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_stories.isNotEmpty) {
      return _buildStoryList();
    } else {
      return _buildUploadPrompt(context);
    }
  }

  Widget _buildStoryList() {
    return Column(
      children: [
        // Create New Tale button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showImageSourceOptions(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 24),
              label: Text(
                'Create New Tale',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        
        // Stories list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _stories.length,
            itemBuilder: (context, index) {
              final story = _stories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: AppTheme.flatWhiteCard,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: AppColors.lightGrey,
                    ),
                    child: const Icon(Icons.book, color: AppColors.primary, size: 32),
                  ),
                  title: Text(
                    story.title.isNotEmpty ? story.title : 'Untitled Story',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Tap to read and listen',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                  trailing: story.status == StoryStatus.pending 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_ios, color: AppColors.grey, size: 16),
                  onTap: story.status == StoryStatus.approved ? () {
                    Navigator.pushNamed(
                      context,
                      '/story-display',
                      arguments: story,
                    );
                  } : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Centered mascot with proper size
          SvgPicture.asset(
            AppAssets.miraReady,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),

          // Upload button - FLAT design
          ElevatedButton(
            onPressed: () => _showImageSourceOptions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.textDark,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0, // NO shadow
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
            child: Text(
              'upload',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Help text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Upload a drawing or photo to create a story',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterButton(Icons.home, () {
            Navigator.pop(context);
          }),
          _buildFooterButton(Icons.explore, () {
            // Navigate to explore
          }),
          _buildFooterButton(Icons.settings, () {
            // Navigate to settings
          }),
        ],
      ),
    );
  }

  Widget _buildFooterButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        // NO shadows, completely flat
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: AppColors.textLight),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0, // NO shadow
          padding: const EdgeInsets.all(16),
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
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
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
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
