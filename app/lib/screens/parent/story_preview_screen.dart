import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/story.dart';
import '../../generated/app_localizations.dart';

class StoryPreviewScreen extends StatefulWidget {
  final Story? story;
  
  const StoryPreviewScreen({super.key, this.story});

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  bool _isPlaying = false;
  String _feedbackText = '';
  Story? _story;
  
  @override
  void initState() {
    super.initState();
    _story = widget.story;
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get story from route arguments if not provided in constructor
    if (_story == null) {
      _story = ModalRoute.of(context)?.settings.arguments as Story?;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_story == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.storyPreview),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Text('No story data available'),
        ),
      );
    }
    
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
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _story!.imageUrl != null && _story!.imageUrl!.isNotEmpty
              ? Image.network(
                  _story!.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey.withValues(alpha: 128),
                      ),
                    );
                  },
                )
              : Center(
                  child: Icon(
                    Icons.image,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 128),
                  ),
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
          Text(
            _story!.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _story!.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textDark,
              height: 1.5,
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
        Text(
          'Feedback (optional):',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
            hintText: AppLocalizations.of(context)!.enterFeedbackOrChanges,
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
            child: Text(AppLocalizations.of(context)!.decline),
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
            child: Text(AppLocalizations.of(context)!.approve),
          ),
        ),
      ],
    );
  }
}
