import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/story.dart';

class StoryDisplayScreen extends StatefulWidget {
  const StoryDisplayScreen({super.key});

  @override
  State<StoryDisplayScreen> createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  double _fontSize = 16.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _currentPosition == Duration.zero;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildStoryContentWithImage(Story story) {
    // Split story content by paragraphs (double newlines or periods followed by space)
    final paragraphs = story.content.split(RegExp(r'\n\s*\n|\. (?=[A-Z])')).where((p) => p.trim().isNotEmpty).toList();
    
    List<Widget> contentWidgets = [];
    
    for (int i = 0; i < paragraphs.length; i++) {
      String paragraph = paragraphs[i].trim();
      
      // Ensure paragraph ends with proper punctuation if it doesn't already
      if (!paragraph.endsWith('.') && !paragraph.endsWith('!') && !paragraph.endsWith('?') && i < paragraphs.length - 1) {
        paragraph += '.';
      }
      
      // Add paragraph text
      contentWidgets.add(
        Text(
          paragraph,
          style: GoogleFonts.manrope(
            fontSize: _fontSize,
            height: 1.8,
            color: AppColors.textDark,
          ),
        ),
      );
      
      // Add spacing after paragraph
      if (i < paragraphs.length - 1) {
        contentWidgets.add(const SizedBox(height: 20));
      }
      
      // Add image after second paragraph if there are more paragraphs
      if (i == 1 && paragraphs.length > 2) {
        contentWidgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/stories/default-cover.png',
                height: 250,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        color: AppColors.grey,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Story story = ModalRoute.of(context)!.settings.arguments as Story;

    return Scaffold(
      backgroundColor: AppTheme.whiteScreenBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Clean top app bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      story.title.isNotEmpty ? story.title : 'Your Story',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Story content area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: _buildStoryContentWithImage(story),
                ),
              ),
            ),

            // Bottom controls bar
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildBottomControls(story),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(Story story) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio progress bar (if audio available)
        if (story.audioUrl != null && _totalDuration.inSeconds > 0) ...[
          _buildProgressBar(),
          const SizedBox(height: 16),
        ],
        
        // Main controls row
        Row(
          children: [
            // Text size control
            _buildTextSizeButton(),
            const SizedBox(width: 16),
            
            // Play/pause button (center)
            Expanded(
              child: _buildPlayButton(story),
            ),
            
            const SizedBox(width: 16),
            
            // Additional controls
            _buildMenuButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _totalDuration.inMilliseconds > 0 
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds 
        : 0.0;
        
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_currentPosition),
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
            Text(
              _formatDuration(_totalDuration),
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.lightGrey,
            thumbColor: AppColors.primary,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) async {
              final position = Duration(
                milliseconds: (value * _totalDuration.inMilliseconds).round(),
              );
              await _audioPlayer.seek(position);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(Story story) {
    if (story.audioUrl == null) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            'No audio available',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _toggleAudio(story.audioUrl!),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: _isLoading 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.white,
                size: 32,
              ),
        ),
      ),
    );
  }

  Widget _buildTextSizeButton() {
    return GestureDetector(
      onTap: _toggleTextSize,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.text_fields,
          color: AppColors.textDark,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return GestureDetector(
      onTap: _showOptionsMenu,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.more_vert,
          color: AppColors.textDark,
          size: 24,
        ),
      ),
    );
  }

  void _toggleTextSize() {
    setState(() {
      if (_fontSize == 16.0) {
        _fontSize = 20.0;
      } else if (_fontSize == 20.0) {
        _fontSize = 24.0;
      } else {
        _fontSize = 16.0;
      }
    });
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Story Options',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Text Size'),
              subtitle: Text('Current: ${_fontSize.toInt()}pt'),
              onTap: () {
                Navigator.pop(context);
                _toggleTextSize();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Another Story'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _toggleAudio(String audioUrl) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
