import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/story.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../generated/app_localizations.dart';

class StoryDisplayScreen extends StatefulWidget {
  const StoryDisplayScreen({super.key});

  @override
  State<StoryDisplayScreen> createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // Story narration
  final AudioPlayer _backgroundPlayer = AudioPlayer(); // Background music
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _backgroundMusicEnabled = true;
  bool _isBackgroundPlaying = false;
  int _fontSizeIndex = 0; // 0=bodyMedium(16px), 1=headlineMedium(20px), 2=headlineLarge(24px)
  double _backgroundVolume = 0.2; // Initial volume for background music intro
  double _backgroundVolumeMid = 0.1; // Medium volume as narration approaches
  double _backgroundVolumeNarration = 0.01; // Very low volume during narration
  bool _hasStartedNarration = false; // Track if narration has already started
  int _fadeDurationSeconds = 10; // Duration for smooth volume fade
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _setupBackgroundMusic();
  }

  void _setupAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          // Don't override _isPlaying if we manually set it during staging
          if (state == PlayerState.stopped || state == PlayerState.paused) {
            _isPlaying = false;
          }
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

  void _setupBackgroundMusic() async {
    try {
      // Configure background music for looping
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(_backgroundVolume);
      
      // Set up background music state listener
      _backgroundPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (mounted) {
          setState(() {
            _isBackgroundPlaying = state == PlayerState.playing;
          });
        }
      });
    } catch (e) {
      print('Error setting up background music: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
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
          style: _getStoryTextStyle(context),
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
            Container(
              width: double.infinity,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveBreakpoints.getResponsivePadding(context),
                    vertical: 16,
                  ),
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),

            // Story content area
            Expanded(
              child: Container(
                width: double.infinity,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
                    constraints: const BoxConstraints(maxWidth: 1200),
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveBreakpoints.getResponsivePadding(context),
                    ),
                    padding: EdgeInsets.all(ResponsiveBreakpoints.getResponsivePadding(context)),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                    child: SingleChildScrollView(
                      child: _buildStoryContentWithImage(story),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls bar
            Container(
              width: double.infinity,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1200),
                  margin: EdgeInsets.all(ResponsiveBreakpoints.getResponsivePadding(context)),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveBreakpoints.getResponsivePadding(context),
                    vertical: 16,
                  ),
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
              ),
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
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              _formatDuration(_totalDuration),
              style: Theme.of(context).textTheme.labelSmall,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      _fontSizeIndex = (_fontSizeIndex + 1) % 3;
    });
  }

  TextStyle _getStoryTextStyle(BuildContext context) {
    switch (_fontSizeIndex) {
      case 0:
        return Theme.of(context).textTheme.bodyMedium!.copyWith(
          height: 1.8,
          color: AppColors.textDark,
        );
      case 1:
        return Theme.of(context).textTheme.headlineMedium!.copyWith(
          height: 1.8,
          color: AppColors.textDark,
          fontWeight: FontWeight.normal, // Override bold for reading
        );
      case 2:
        return Theme.of(context).textTheme.headlineLarge!.copyWith(
          height: 1.8,
          color: AppColors.textDark,
          fontWeight: FontWeight.normal, // Override bold for reading
        );
      default:
        return Theme.of(context).textTheme.bodyMedium!.copyWith(
          height: 1.8,
          color: AppColors.textDark,
        );
    }
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(AppLocalizations.of(context)!.textSize),
              subtitle: Text(AppLocalizations.of(context)!.currentFontSize([16, 20, 24][_fontSizeIndex])),
              onTap: () {
                Navigator.pop(context);
                _toggleTextSize();
              },
            ),
            ListTile(
              leading: Icon(_backgroundMusicEnabled ? Icons.music_note : Icons.music_off),
              title: Text(AppLocalizations.of(context)!.backgroundMusic),
              subtitle: Text(_backgroundMusicEnabled ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.disabled),
              onTap: () {
                Navigator.pop(context);
                _toggleBackgroundMusic();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(AppLocalizations.of(context)!.createAnotherStory),
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
        // Pause both story and background music
        await _audioPlayer.pause();
        if (_backgroundMusicEnabled && _isBackgroundPlaying) {
          await _backgroundPlayer.pause();
        }
      } else {
        if (!_hasStartedNarration) {
          // First time playing - do full staging
          await _startAudioWithStaging(audioUrl);
        } else {
          // Resume from pause - just continue playback
          setState(() {
            _isPlaying = true;
          });
          
          await _audioPlayer.resume();
          if (_backgroundMusicEnabled && !_isBackgroundPlaying) {
            await _backgroundPlayer.setVolume(_backgroundVolumeNarration);
            await _backgroundPlayer.resume();
          }
        }
      }
    } catch (e) {
      // Reset UI state on error
      setState(() {
        _isPlaying = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToPlayAudio(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startAudioWithStaging(String audioUrl) async {
    // Immediately update UI to show playing state and get audio duration
    setState(() {
      _isPlaying = true;
    });
    
    // Prepare the audio source to get duration but don't play yet
    await _audioPlayer.setSource(UrlSource(audioUrl));
    
    // Start background music first (behind the scenes)
    if (_backgroundMusicEnabled && !_isBackgroundPlaying) {
      await _startBackgroundMusicIntro();
    }
    
    // Wait 3 seconds at 0.2 volume
    await Future.delayed(const Duration(seconds: 3));
    
    // Gradually lower to 0.2 over 2 seconds (from 3rd to 5th second)
    if (_backgroundMusicEnabled && _isBackgroundPlaying) {
      print('Gradually lowering background music volume from $_backgroundVolume to $_backgroundVolumeMid');
      await _backgroundPlayer.setVolume(_backgroundVolumeMid);
    }
    
    // Start story narration at 3rd second
    await _audioPlayer.resume();
    _hasStartedNarration = true;
    
    // Gradually fade to very low volume over time
    _fadeBackgroundMusic();
  }

  void _fadeBackgroundMusic() {
    // Create a smooth fade from 0.1 to 0.01 over configurable duration
    _smoothVolumeFade();
  }

  void _smoothVolumeFade() async {
    double currentVolume = _backgroundVolumeMid; // Start at 0.1
    double targetVolume = _backgroundVolumeNarration; // End at 0.01
    double stepSize = (currentVolume - targetVolume) / _fadeDurationSeconds;
    
    for (int i = 0; i < _fadeDurationSeconds; i++) {
      await Future.delayed(const Duration(seconds: 1));
      
      if (_backgroundMusicEnabled && _isBackgroundPlaying) {
        currentVolume -= stepSize;
        print('Smooth fade step ${i + 1}/$_fadeDurationSeconds: volume ${currentVolume.toStringAsFixed(3)}');
        await _backgroundPlayer.setVolume(currentVolume);
      } else {
        break; // Stop fading if background music is disabled or stopped
      }
    }
  }

  Future<void> _startBackgroundMusic() async {
    try {
      await _backgroundPlayer.setVolume(_backgroundVolumeNarration);
      await _backgroundPlayer.play(AssetSource('audio/Enchanted Forest Loop.mp3'));
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  Future<void> _startBackgroundMusicIntro() async {
    try {
      print('Starting background music at volume $_backgroundVolume');
      await _backgroundPlayer.setVolume(_backgroundVolume);
      await _backgroundPlayer.play(AssetSource('audio/Enchanted Forest Loop.mp3'));
    } catch (e) {
      print('Error playing background music intro: $e');
    }
  }

  Future<void> _toggleBackgroundMusic() async {
    setState(() {
      _backgroundMusicEnabled = !_backgroundMusicEnabled;
    });

    if (_backgroundMusicEnabled && _isPlaying) {
      // Start background music if story is playing
      await _startBackgroundMusic();
    } else if (!_backgroundMusicEnabled && _isBackgroundPlaying) {
      // Stop background music
      await _backgroundPlayer.stop();
    }
  }
}
