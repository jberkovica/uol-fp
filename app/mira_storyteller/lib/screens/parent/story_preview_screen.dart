import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class StoryPreviewScreen extends StatefulWidget {
  const StoryPreviewScreen({super.key});

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  bool _isPlaying = false;
  String _feedbackText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story preview'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(),
              const SizedBox(height: 24),
              _buildStoryContent(),
              const SizedBox(height: 24),
              _buildAudioControls(),
              const SizedBox(height: 32),
              _buildFeedbackSection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          // In a real app, display the actual uploaded image
          child: Icon(
            Icons.image,
            size: 80,
            color: Colors.grey.withValues(alpha: 128),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Froggy Frog',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Froggy was a tiny green frog. He lived on a big lily pad in a quiet pond. One day, Froggy decided to explore beyond his lily pad. He hopped to a nearby rock, then to the shore. Along the way, Froggy met a friendly butterfly who showed him beautiful flowers at the pond\'s edge. Froggy had never seen such colorful plants before! When the sun began to set, Froggy hopped all the way back to his lily pad. He was happy to be home, but excited for more adventures tomorrow.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            // In a real app, restart audio from beginning
          },
          icon: const Icon(Icons.replay),
          color: AppColors.primary,
          iconSize: 36,
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isPlaying = !_isPlaying;
              // In a real app, play/pause audio
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            // In a real app, download audio file
          },
          icon: const Icon(Icons.download),
          color: AppColors.primary,
          iconSize: 36,
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Feedback (optional):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() {
              _feedbackText = value;
            });
          },
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter any feedback or request changes...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // In a real app, approve story with API call including any feedback
              // Then show confirmation and navigate back
              final String message = _feedbackText.isEmpty
                ? 'Story approved successfully!' 
                : 'Story approved with feedback';
                
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Approve'),
          ),
        ),
      ],
    );
  }
}
