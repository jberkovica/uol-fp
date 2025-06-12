import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/character_avatar.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  // For demonstration purposes, this allows toggling between views
  final bool _hasStories = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader('My tales'),
              Expanded(
                child: _buildContent(context),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    // This is no longer dead code as _hasStories can be toggled
    if (_hasStories) {
      return _buildStoryList();
    } else {
      return _buildUploadPrompt(context);
    }
  }

  Widget _buildStoryList() {
    // Mock stories data for demonstration
    // In a real app, this would come from a database or API
    final mockStories = [
      {'title': 'The Magical Forest', 'image': null},
      {'title': 'Space Adventure', 'image': null},
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: mockStories.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.lightGrey,
              ),
              // This would be the story thumbnail
              child: Icon(Icons.image, color: AppColors.grey),
            ),
            title: Text(
              'Story Title',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('Tap to listen'),
            onTap: () {
              Navigator.pushNamed(context, '/story-playback');
            },
          ),
        );
      },
    );
  }

  Widget _buildUploadPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character mascot
          const CharacterAvatar(
            radius: 60,
            characterType: CharacterType.hero2,
          ),
          const SizedBox(height: 40),
          // Upload button
          ElevatedButton(
            onPressed: () => _showImageSourceOptions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Upload',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Help text
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Upload a drawing or photo to create a story',
              textAlign: TextAlign.center,
              style: TextStyle(
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
          IconButton(
            onPressed: () {
              Navigator.pop(context); // Go back to profile select
            },
            icon: const Icon(Icons.home, size: 32),
            color: AppColors.textDark,
          ),
          Container(width: 10), // Spacer
          IconButton(
            onPressed: () {
              // Navigate to settings or additional features
            },
            icon: const Icon(Icons.settings, size: 28),
            color: AppColors.textDark.withValues(alpha: 179),
          ),
        ],
      ),
    );
  }
  
  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose an option',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceButton(
                  context,
                  Icons.camera_alt,
                  'Camera',
                  () {
                    Navigator.pop(context);
                    // Handle camera selection
                    Navigator.pushNamed(context, '/processing-screen');
                  },
                ),
                _buildImageSourceButton(
                  context,
                  Icons.photo_library,
                  'Gallery',
                  () {
                    Navigator.pop(context);
                    // Handle gallery selection
                    Navigator.pushNamed(context, '/processing-screen');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageSourceButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
