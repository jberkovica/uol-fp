import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/story.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../generated/app_localizations.dart';
import '../../services/logging_service.dart';

class StoryDisplayScreen extends StatefulWidget {
  const StoryDisplayScreen({super.key});

  @override
  State<StoryDisplayScreen> createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> with TickerProviderStateMixin {
  static final _logger = LoggingService.getLogger('StoryDisplayScreen');
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
  
  // Animation controller for gradient
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _setupBackgroundMusic();
    
    // Initialize gradient animation
    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
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
      _logger.e('Error setting up background music', error: e);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    _gradientController.dispose();
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
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/photo.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
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
            // Story content area with scrollable header and fade effect
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveBreakpoints.getResponsivePadding(context),
                      vertical: 8,
                    ),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header - now scrollable
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: SvgPicture.asset(
                                      'assets/icons/arrow-left.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                                    ),
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
                              const SizedBox(height: 24),
                              // Story content
                              _buildStoryContentWithImage(story),
                              const SizedBox(height: 100), // Space for floating controls
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient fade effect at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.whiteScreenBackground.withValues(alpha: 0.0),
                            AppTheme.whiteScreenBackground.withValues(alpha: 0.1),
                            AppTheme.whiteScreenBackground.withValues(alpha: 0.4),
                            AppTheme.whiteScreenBackground.withValues(alpha: 0.8),
                            AppTheme.whiteScreenBackground,
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom controls bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: _buildBottomControls(story),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(Story story) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Music icon (left) - yellow-violet gradient icon
          _buildGradientMusicIcon(
            'assets/icons/music-heart.svg',
            onPressed: () {
              // Will implement music functionality later
            },
          ),
          const SizedBox(width: 8), // Slightly more space between elements
          
          // Main audio controls in violet container (center)
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 5),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Skip backward (-10s) - Material icon, white
                _buildWhiteMaterialIconButton(
                  Icons.replay_10,
                  onPressed: story.audioUrl != null ? () => _skipBackward() : null,
                ),
                const SizedBox(width: 4),
                
                // Play/pause button (slightly larger)
                _buildWhiteIconButton(
                  _isPlaying ? 'assets/icons/player-pause-filled.svg' : 'assets/icons/player-play-filled.svg',
                  onPressed: story.audioUrl != null ? () => _toggleAudio(story.audioUrl!) : null,
                  isLoading: _isLoading,
                  size: 52,
                ),
                const SizedBox(width: 4),
                
                // Skip forward (+10s) - Material icon, white
                _buildWhiteMaterialIconButton(
                  Icons.forward_10,
                  onPressed: story.audioUrl != null ? () => _skipForward() : null,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8), // Slightly more space between elements
          // Controls/Settings icon (right)
          _buildGreyIconButton(
            'assets/icons/settings.svg',
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
    );
  }


  // Primary button (purple background for play/pause)
  Widget _buildPrimaryIconButton(
    String iconPath, {
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
            )
          : SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            ),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(52, 52), // Slightly larger for primary action
        maximumSize: const Size(52, 52),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
      ),
    );
  }

  // Grey icon buttons (no background, just grey icons)
  Widget _buildGreyIconButton(
    String iconPath, {
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          onPressed != null ? AppColors.grey600 : AppColors.grey400,
          BlendMode.srcIn,
        ),
      ),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.grey600,
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Dark grey icon buttons (no background, just dark grey icons)
  Widget _buildDarkGreyIconButton(
    String iconPath, {
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          onPressed != null ? AppColors.grey700 : AppColors.grey400,
          BlendMode.srcIn,
        ),
      ),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.grey700,
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // White Material icon buttons for inside violet container
  Widget _buildWhiteMaterialIconButton(
    IconData icon, {
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 24,
        color: AppColors.white,
      ),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.white,
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // White icon buttons for inside violet container (SVG icons)
  Widget _buildWhiteIconButton(
    String iconPath, {
    VoidCallback? onPressed,
    bool isLoading = false,
    double size = 48,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
            )
          : SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            ),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.white,
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Violet icon buttons (violet circle background with white icons)
  Widget _buildVioletIconButton(
    String iconPath, {
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
            )
          : SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            ),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
      ),
    );
  }

  // Animated gradient music icon (no background, just animated gradient-colored icon)
  Widget _buildGradientMusicIcon(
    String iconPath, {
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.secondary, AppColors.primary], // Yellow to violet
              begin: Alignment.lerp(
                Alignment.topLeft,
                Alignment.bottomLeft,
                _gradientController.value,
              )!,
              end: Alignment.lerp(
                Alignment.bottomRight,
                Alignment.topRight,
                _gradientController.value,
              )!,
            ).createShader(bounds),
            child: SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          );
        },
      ),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }


  void _toggleTextSize() {
    setState(() {
      _fontSizeIndex = (_fontSizeIndex + 1) % 3;
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
              'Story Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/text-size.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.textGrey, BlendMode.srcIn),
              ),
              title: const Text('Text Size'),
              subtitle: DropdownButton<int>(
                value: _fontSizeIndex,
                underline: Container(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Small (16px)')),
                  DropdownMenuItem(value: 1, child: Text('Medium (20px)')),
                  DropdownMenuItem(value: 2, child: Text('Large (24px)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _fontSizeIndex = value;
                    });
                  }
                },
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textGrey,
                ),
                dropdownColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBackgroundMusic() {
    setState(() {
      _backgroundMusicEnabled = !_backgroundMusicEnabled;
    });
    
    if (_backgroundMusicEnabled && _isPlaying) {
      _startBackgroundMusic();
    } else {
      _backgroundPlayer.stop();
    }
  }

  TextStyle _getStoryTextStyle(BuildContext context) {
    switch (_fontSizeIndex) {
      case 0:
        return Theme.of(context).textTheme.bodyMedium!.copyWith(
          height: 1.5,
          color: AppColors.textDark,
        );
      case 1:
        return Theme.of(context).textTheme.headlineMedium!.copyWith(
          height: 1.5,
          color: AppColors.textDark,
          fontWeight: FontWeight.normal, // Override bold for reading
        );
      case 2:
        return Theme.of(context).textTheme.headlineLarge!.copyWith(
          height: 1.5,
          color: AppColors.textDark,
          fontWeight: FontWeight.normal, // Override bold for reading
        );
      default:
        return Theme.of(context).textTheme.bodyMedium!.copyWith(
          height: 1.5,
          color: AppColors.textDark,
        );
    }
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
      _logger.d('Gradually lowering background music volume from $_backgroundVolume to $_backgroundVolumeMid');
      await _backgroundPlayer.setVolume(_backgroundVolumeMid);
    }
    
    // Start story narration at 3rd second
    await _audioPlayer.resume();
    _hasStartedNarration = true;
    
    // Duration will be detected via _tryGetDuration during position updates
    
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
        _logger.d('Smooth fade step ${i + 1}/$_fadeDurationSeconds: volume ${currentVolume.toStringAsFixed(3)}');
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
      _logger.e('Error playing background music', error: e);
    }
  }

  Future<void> _startBackgroundMusicIntro() async {
    try {
      _logger.d('Starting background music at volume $_backgroundVolume');
      await _backgroundPlayer.setVolume(_backgroundVolume);
      await _backgroundPlayer.play(AssetSource('audio/Enchanted Forest Loop.mp3'));
    } catch (e) {
      _logger.e('Error playing background music intro', error: e);
    }
  }

  Future<void> _restartAudio(String audioUrl) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(UrlSource(audioUrl));
      setState(() {
        _currentPosition = Duration.zero;
        _isPlaying = false;
      });
    } catch (e) {
      _logger.e('Error restarting audio', error: e);
    }
  }

  Future<void> _skipForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    await _audioPlayer.seek(newPosition);
  }

  Future<void> _skipBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    // Ensure we don't go below 0
    final clampedPosition = newPosition.isNegative ? Duration.zero : newPosition;
    await _audioPlayer.seek(clampedPosition);
  }

}
