import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_theme.dart';

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
      backgroundColor: AppColors.backgroundYellow, // FLAT yellow background
      body: SafeArea(
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
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.flatWhiteCard, // FLAT white card
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: AppColors.lightGrey,
                // NO shadows
              ),
              // This would be the story thumbnail
              child: const Icon(Icons.image, color: AppColors.grey),
            ),
            title: Text(
              'Story Title',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Text(
              'Tap to listen',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          elevation: 0, // NO shadow
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Choose Image Source',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Camera', style: GoogleFonts.manrope()),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/processing');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.manrope()),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/processing');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
