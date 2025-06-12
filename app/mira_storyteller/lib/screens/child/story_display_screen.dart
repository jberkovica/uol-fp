import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class StoryDisplayScreen extends StatefulWidget {
  const StoryDisplayScreen({super.key});

  @override
  State<StoryDisplayScreen> createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _animationController;
  
  // In a real app, this would come from the backend
  final Map<String, dynamic> _mockStory = {
    'title': 'Froggy Frog',
    'image': null, // Would be a URL or asset path
    'text': 'Froggy was a tiny green frog. He lived on a big lily pad in a quiet pond. One day, Froggy decided to explore beyond his lily pad. He hopped to a nearby rock, then to the shore. Along the way, Froggy met a friendly butterfly who showed him beautiful flowers at the pond\'s edge. Froggy had never seen such colorful plants before! When the sun began to set, Froggy hopped all the way back to his lily pad. He was happy to be home, but excited for more adventures tomorrow.',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animationController.forward();
        // In a real app, we would start audio playback here
      } else {
        _animationController.reverse();
        // In a real app, we would pause audio playback here
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Story preview',
          style: TextStyle(color: AppColors.textDark),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.primary],
            stops: [0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStoryImage(),
              _buildStoryContent(),
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryImage() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: Colors.amber,
          width: 5,
        ),
      ),
      child: Center(
        // In a real app, this would be an Image widget with the actual image
        child: Icon(
          Icons.image,
          size: 80,
          color: Colors.grey.withValues(alpha: 128),
        ),
      ),
    );
  }

  Widget _buildStoryContent() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 26),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _mockStory['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _mockStory['text'],
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            onPressed: () {
              // In a real app, restart story from beginning
            },
            backgroundColor: AppColors.primary.withValues(alpha: 230),
            icon: Icons.replay,
          ),
          _buildActionButton(
            onPressed: _togglePlayPause,
            backgroundColor: AppColors.primary,
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            iconSize: 40,
          ),
          _buildActionButton(
            onPressed: () {
              // In a real app, share story functionality
            },
            backgroundColor: AppColors.primary.withValues(alpha: 230),
            icon: Icons.share,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    double iconSize = 30,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        minimumSize: const Size(60, 60),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
