import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/story.dart';
import '../../services/mock_story_service.dart';

class StoryDisplayScreen extends StatefulWidget {
  const StoryDisplayScreen({super.key});

  @override
  State<StoryDisplayScreen> createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> {
  final MockStoryService _storyService = MockStoryService();
  Story? _currentStory;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  void _loadStory() async {
    final stories = await _storyService.getApprovedStories();
    if (stories.isNotEmpty) {
      setState(() {
        _currentStory = stories.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStory == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPurple,
        body: Center(
          child: Text(
            'No story available',
            style: GoogleFonts.manrope(
              color: AppColors.textLight,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPurple, // FLAT purple background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildStoryContent(),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.textLight, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0, // NO shadow
            ),
          ),
          Expanded(
            child: Text(
              'Story preview',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for close button
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Image container - FLAT design, NO gradients
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.secondary, // FLAT yellow background
              borderRadius: BorderRadius.all(Radius.circular(16)),
              // NO shadows, NO gradients, completely flat
            ),
            child: Center(
              child: _currentStory!.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _currentStory!.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Icon(
                      Icons.image,
                      size: 80,
                      color: AppColors.textDark.withOpacity(0.3),
                    ),
            ),
          ),

          // Story text container - FLAT design
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.flatCardDecoration, // FLAT white container
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStory!.title,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _currentStory!.content,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.backgroundPurple, // FLAT purple background
        // NO gradients, NO shadows
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.refresh,
            onPressed: () {
              // Regenerate story
            },
          ),
          _buildPlayButton(),
          _buildControlButton(
            icon: Icons.share,
            onPressed: () {
              // Share story
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        // NO shadows, completely flat
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary, size: 28),
        iconSize: 28,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0, // NO shadow
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondary, // FLAT yellow
        shape: BoxShape.circle,
        // NO shadows, completely flat
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            _isPlaying = !_isPlaying;
          });
        },
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColors.textDark,
          size: 32,
        ),
        iconSize: 32,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0, // NO shadow
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
