import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/story.dart';
import '../../services/ai_story_service.dart';
import '../../services/logging_service.dart';
import '../../generated/app_localizations.dart';

class StoryPreviewScreen extends StatefulWidget {
  final Story? story;
  
  const StoryPreviewScreen({super.key, this.story});

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  static final _logger = LoggingService.getLogger('StoryPreviewScreen');
  bool _isPlaying = false;
  bool _isLoading = false;
  Story? _story;
  double _scrollOffset = 0.0;
  
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
  void dispose() {
    super.dispose();
  }

  Future<void> _reviewStory(bool approved, {String? feedback}) async {
    if (_story == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await AIStoryService().reviewStory(
        _story!.id, 
        approved, 
        feedback: feedback?.trim().isEmpty == true ? null : feedback?.trim()
      );
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved 
                ? AppLocalizations.of(context)!.storyApprovedSuccessfully
                : AppLocalizations.of(context)!.storyDeclined,
            ),
            backgroundColor: approved ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Navigate back to parent dashboard
        Navigator.pop(context, true); // Return true to indicate story was reviewed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reviewing story: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeclineDialog() {
    String declineReason = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.declineStory,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.pleaseProvideReason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => declineReason = value,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.declineReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewStory(false, feedback: declineReason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              AppLocalizations.of(context)!.decline,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuggestEditDialog() {
    String suggestions = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.suggestEdits,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.provideSuggestions,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => suggestions = value,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.suggestionsHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement story regeneration with suggestions
              // Use the 'suggestions' variable here when implementing regeneration
              _logger.d('Suggestions for regeneration: $suggestions');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.regeneratingStory),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              AppLocalizations.of(context)!.regenerateStory,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_story == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context)!.storyPreview,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.noStoryDataAvailable,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Layer 1: Purple background (fills entire screen)
          Container(
            color: AppColors.primary,
          ),
          
          // Layer 2: Fixed header content (stays under white container)
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppTheme.getGlobalPadding(context),
                right: AppTheme.getGlobalPadding(context),
                top: AppTheme.screenHeaderTopPadding,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.storyPreview,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Layer 3: Scrollable white content with parallax effect
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollUpdateNotification) {
                  if (notification.metrics.axis == Axis.vertical) {
                    setState(() {
                      _scrollOffset = notification.metrics.pixels;
                    });
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Spacer to push white container down with parallax effect
                    SizedBox(height: (220 + (-_scrollOffset * 0.5)).clamp(120, 220)),
                    
                    // White content container
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.getGlobalPadding(context)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            
                            // Story title
                            Text(
                              _story!.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Image preview
                            _buildImagePreview(),
                            
                            const SizedBox(height: 24),
                            
                            // Audio controls
                            _buildAudioControls(),
                            
                            const SizedBox(height: 32),
                            
                            // Story content
                            _buildStoryContent(),
                            
                            const SizedBox(height: 32),
                            
                            // Action buttons
                            _buildActionButtons(),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.secondary,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: _story!.imageUrl != null && _story!.imageUrl!.isNotEmpty
              ? Image.network(
                  _story!.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.image,
                            size: 48,
                            color: AppColors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.imageNotAvailable,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.image,
                        size: 48,
                        color: AppColors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.imageNotAvailable,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Restart button
          _buildAudioButton(
            icon: LucideIcons.rotateCcw,
            onPressed: () {
              // TODO: Implement restart audio
            },
          ),
          
          // Play/Pause button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                  // TODO: Implement play/pause audio
                });
              },
              icon: Icon(
                _isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: Colors.white,
                size: 32,
              ),
              iconSize: 56,
            ),
          ),
          
          // Download button
          _buildAudioButton(
            icon: LucideIcons.download,
            onPressed: () {
              // TODO: Implement download audio
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        iconSize: 48,
      ),
    );
  }

  Widget _buildStoryContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightGrey,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _story!.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textDark,
          height: 1.6,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action: Approve
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _reviewStory(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              disabledBackgroundColor: AppColors.success.withValues(alpha: 128),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.check, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.approve,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Secondary actions row
        Row(
          children: [
            // Suggest edits
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _showSuggestEditDialog,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.secondary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.edit, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.suggestEdits,
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Decline
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _showDeclineDialog,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.x, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.decline,
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}