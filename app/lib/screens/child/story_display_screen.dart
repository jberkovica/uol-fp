import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/story.dart';
import '../../models/background_music.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../generated/app_localizations.dart';
import '../../services/logging_service.dart';
import '../../services/background_music_service.dart';
import '../../services/story_service.dart';

/// Enum for simplified playback state management
enum PlaybackState {
  stopped,    // Initial state, no audio loaded
  playing,    // Audio is playing (user hears background music or narration)
  paused,     // Playback is paused
}

/// Timeline configuration for audio coordination
class AudioTimeline {
  final Duration introLength;   // Background music alone before narration
  final Duration outroLength;   // Graceful ending fade duration
  final Duration fadeLength;    // Background volume fade duration
  
  const AudioTimeline({
    this.introLength = const Duration(seconds: 3),
    this.outroLength = const Duration(seconds: 2),
    this.fadeLength = const Duration(seconds: 10),
  });
  
  // Preset configurations for easy experimentation
  static const AudioTimeline quick = AudioTimeline(
    introLength: Duration(seconds: 1),
    outroLength: Duration(seconds: 1),
    fadeLength: Duration(seconds: 5),
  );
  
  static const AudioTimeline standard = AudioTimeline(
    introLength: Duration(seconds: 3),
    outroLength: Duration(seconds: 2),
    fadeLength: Duration(seconds: 10),
  );
  
  static const AudioTimeline cinematic = AudioTimeline(
    introLength: Duration(seconds: 5),
    outroLength: Duration(seconds: 4),
    fadeLength: Duration(seconds: 15),
  );
}

class StoryDisplayScreen extends StatefulWidget {
  const StoryDisplayScreen({super.key});

  @override
  State<StoryDisplayScreen> createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> with TickerProviderStateMixin {
  static final _logger = LoggingService.getLogger('StoryDisplayScreen');
  final AudioPlayer _audioPlayer = AudioPlayer(); // Story narration
  final AudioPlayer _backgroundPlayer = AudioPlayer(); // Background music
  
  // Single source of truth for play/pause state
  PlaybackState _playbackState = PlaybackState.stopped;
  
  // Timeline configuration - easy to experiment with different values!
  // Try: AudioTimeline.quick, AudioTimeline.standard, AudioTimeline.cinematic
  // Or custom: AudioTimeline(introLength: Duration(seconds: 2), outroLength: Duration(seconds: 4))
  final AudioTimeline _timeline = AudioTimeline.standard;
  
  // Audio coordination
  final bool _backgroundMusicEnabled = true;
  bool _hasStartedNarration = false;
  Timer? _narrationStartTimer;
  Timer? _outroFadeTimer;
  
  // UI configuration
  int _fontSizeIndex = 0; // 0=bodyMedium(16px), 1=headlineMedium(20px), 2=headlineLarge(24px)
  
  // Audio volumes
  final double _backgroundVolumeIntro = 0.2; // Initial volume for background music intro
  final double _backgroundVolumeMid = 0.1;   // Medium volume as narration approaches
  final double _backgroundVolumeNarration = 0.01; // Very low volume during narration
  
  // Playback tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Animation controller for gradient
  late AnimationController _gradientController;
  
  // Background music selection state
  String? _currentTrackFilename;
  Story? _updatedStory; // Store updated story data
  bool _hasRefreshedData = false; // Prevent multiple refreshes

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _setupBackgroundMusic();
    _loadCurrentTrackFilename();
    
    // Initialize gradient animation
    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access context here - refresh story data after widget tree is built
    if (!_hasRefreshedData) {
      _hasRefreshedData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshStoryData();
      });
    }
  }

  /// Refresh story data from backend to ensure we have latest audio URL
  Future<void> _refreshStoryData() async {
    try {
      final Story originalStory = ModalRoute.of(context)!.settings.arguments as Story;
      _logger.d('Refreshing story data for: ${originalStory.id}');
      
      // Get fresh story data from backend
      final freshStory = await StoryService.getStoryById(originalStory.id);
      
      if (mounted) {
        setState(() {
          _updatedStory = freshStory;
        });
        if (freshStory.audioUrl != null) {
          _logger.d('Story data refreshed with audio URL');
        } else {
          _logger.w('Story data refreshed but still missing audio URL');
        }
      }
    } catch (e) {
      _logger.e('Failed to refresh story data', error: e);
    }
  }

  void _loadCurrentTrackFilename() {
    // We'll load this later when we have access to the story from the route
  }

  void _setupAudioListeners() {
    // Main audio (narration) listeners
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          // Update playback state based on actual audio player state
          // Only update if the state change makes sense in our current context
          if (state == PlayerState.stopped) {
            _playbackState = PlaybackState.stopped;
            _hasStartedNarration = false;
          } else if (state == PlayerState.paused && _playbackState == PlaybackState.playing) {
            _playbackState = PlaybackState.paused;
          } else if (state == PlayerState.playing) {
            _playbackState = PlaybackState.playing;
          }
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
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

    // Handle audio completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        _logger.d('Audio playback completed');
        
        // Cancel any pending timers
        _narrationStartTimer?.cancel();
        _outroFadeTimer?.cancel();
        
        setState(() {
          _playbackState = PlaybackState.stopped;
          _hasStartedNarration = false;
          _currentPosition = Duration.zero;
        });
        
        // Stop background music as well
        _backgroundPlayer.stop();
      }
    });

    // Background music listeners for debugging (only log important state changes)
    _backgroundPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        _logger.d('Background music: $state');
      }
    });
  }

  void _setupBackgroundMusic() async {
    try {
      // Configure background music for looping
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(_backgroundVolumeIntro);
    } catch (e) {
      _logger.e('Error setting up background music', error: e);
    }
  }

  @override
  void dispose() {
    // Cancel any pending timers
    _narrationStartTimer?.cancel();
    _outroFadeTimer?.cancel();
    
    // Dispose audio players
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    
    // Dispose animation controller
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
              child: story.coverImageUrl != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final imageWidth = MediaQuery.of(context).size.width * 0.75;
                        return Center(
                          child: SizedBox(
                            width: imageWidth,
                            child: AspectRatio(
                              aspectRatio: 1.0, // Square aspect ratio to match generated images
                              child: Image.network(
                                story.coverImageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to default cover if network image fails
                                  return Image.asset(
                                    'assets/images/stories/default-cover.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
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
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final imageWidth = MediaQuery.of(context).size.width * 0.75;
                        return Center(
                          child: SizedBox(
                            width: imageWidth,
                            child: AspectRatio(
                              aspectRatio: 1.0, // Square aspect ratio to match generated images
                              child: Image.asset(
                                'assets/images/stories/default-cover.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
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
    // Safely get the story argument with proper null checking
    final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    
    if (arguments == null || arguments is! Story) {
      _logger.e('StoryDisplayScreen: Invalid or missing story argument', error: arguments);
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            'Error',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Story not found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Please go back and try again',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    final Story originalStory = arguments;
    // Use updated story if available, otherwise use original
    final Story story = _updatedStory ?? originalStory;
    
    // Debug: Basic story info (only log if audio is missing)
    if (story.audioUrl == null) {
      _logger.w('Story ${story.id} missing audio URL - title: ${story.title}');
    }
    
    // Always update current track filename from story data to ensure we have latest
    if (story.backgroundMusicUrl != null) {
      final extractedFilename = BackgroundMusicService.extractFilenameFromUrl(story.backgroundMusicUrl);
      if (extractedFilename != null && extractedFilename != _currentTrackFilename) {
        _currentTrackFilename = extractedFilename;
      }
    }

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
                                  const SizedBox(width: 16),
                                  // Favorite heart icon
                                  IconButton(
                                    onPressed: () => _toggleFavourite(story),
                                    icon: SvgPicture.asset(
                                      story.isFavourite ? 'assets/icons/heart-filled.svg' : 'assets/icons/heart.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: ColorFilter.mode(
                                        story.isFavourite ? AppColors.error : AppColors.textDark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
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
            onPressed: () => _showMusicSelectionSheet(story),
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
                  _getPlayButtonIcon(),
                  onPressed: story.audioUrl != null ? () {
                    _toggleAudio(story.audioUrl!);
                  } : () {
                    _logger.w('Play button tapped but no audio URL available');
                    _showNoAudioDialog(story);
                  },
                  isLoading: false, // No loading state needed with timeline approach
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
        tapTargetSize: MaterialTapTargetSize.padded, // Changed from shrinkWrap to padded for better touch area
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



  String _getPlayButtonIcon() {
    switch (_playbackState) {
      case PlaybackState.stopped:
        return 'assets/icons/player-play-filled.svg';
      case PlaybackState.playing:
        return 'assets/icons/player-pause-filled.svg';
      case PlaybackState.paused:
        return 'assets/icons/player-play-filled.svg';
    }
  }

  Future<void> _toggleAudio(String audioUrl) async {
    _logger.d('Play button pressed, state: $_playbackState');
    try {
      if (_playbackState == PlaybackState.playing) {
        // Pause both audio streams
        await _pausePlayback();
      } else if (_playbackState == PlaybackState.paused) {
        // Resume playback
        await _resumePlayback();
      } else {
        // Start fresh playback with timeline coordination
        await _startUnifiedPlayback(audioUrl);
      }
    } catch (e) {
      // Reset UI state on error
      setState(() {
        _playbackState = PlaybackState.stopped;
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

  /// Start unified playback with timeline coordination
  Future<void> _startUnifiedPlayback(String audioUrl) async {
    _logger.d('Starting audio playback with background music');
    
    // Immediately show playing state (user will hear background music)
    setState(() {
      _playbackState = PlaybackState.playing;
    });
    
    // Prepare narration audio source
    await _audioPlayer.setSource(UrlSource(audioUrl));
    
    // Start background music immediately (user hears audio now!)
    if (_backgroundMusicEnabled) {
      await _startBackgroundMusic(_backgroundVolumeIntro);
    }
    
    // Schedule narration to start after intro period
    _narrationStartTimer = Timer(_timeline.introLength, () async {
      if (!mounted || _playbackState != PlaybackState.playing) {
        return; // User paused or stopped during intro
      }
      
      _logger.d('Starting narration after intro');
      
      // Lower background volume for narration
      if (_backgroundMusicEnabled) {
        await _backgroundPlayer.setVolume(_backgroundVolumeMid);
      }
      
      // Start narration
      await _audioPlayer.resume();
      _hasStartedNarration = true;
      
      // Start gradual background fade
      _fadeBackgroundMusic();
    });
    
    // Schedule outro fade (if we know story duration)
    if (_totalDuration > Duration.zero) {
      final fadeStartTime = _totalDuration - _timeline.outroLength;
      _outroFadeTimer = Timer(fadeStartTime, () {
        if (mounted && _playbackState == PlaybackState.playing) {
          _logger.d('Starting outro fade');
          _fadeOutGracefully();
        }
      });
    }
  }

  /// Gradually fade background music from mid to narration volume
  void _fadeBackgroundMusic() {
    _smoothVolumeFade(
      from: _backgroundVolumeMid,
      to: _backgroundVolumeNarration,
      duration: _timeline.fadeLength,
    );
  }
  
  /// Fade out both audio streams gracefully
  void _fadeOutGracefully() {
    _smoothVolumeFade(
      from: _backgroundVolumeNarration,
      to: 0.0,
      duration: _timeline.outroLength,
      stopAfterFade: true,
    );
  }

  /// Generic smooth volume fade with configurable parameters
  void _smoothVolumeFade({
    required double from,
    required double to,
    required Duration duration,
    bool stopAfterFade = false,
  }) async {
    if (!_backgroundMusicEnabled) return;
    
    final int steps = duration.inSeconds;
    final double stepSize = (from - to) / steps;
    double currentVolume = from;
    
    _logger.d('Starting volume fade: $from -> $to over ${duration.inSeconds}s');
    
    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(seconds: 1));
      
      // Only continue fading if we're still playing and background music is enabled
      if (!mounted || _playbackState != PlaybackState.playing || !_backgroundMusicEnabled) {
        break;
      }
      
      currentVolume -= stepSize;
      await _backgroundPlayer.setVolume(currentVolume.clamp(0.0, 1.0));
      
      if (i % 3 == 0) { // Log every 3 seconds to reduce noise
        _logger.d('Volume fade step ${i + 1}/$steps: ${currentVolume.toStringAsFixed(3)}');
      }
    }
    
    // Stop playback if requested
    if (stopAfterFade && mounted && _playbackState == PlaybackState.playing) {
      await _stopPlayback();
      setState(() {
        _playbackState = PlaybackState.stopped;
        _hasStartedNarration = false;
      });
    }
  }

  /// Start background music with specified volume
  Future<void> _startBackgroundMusic(double volume) async {
    try {
      final Story originalStory = ModalRoute.of(context)!.settings.arguments as Story;
      final Story story = _updatedStory ?? originalStory;
      
      if (story.backgroundMusicUrl != null) {
        await _backgroundPlayer.setVolume(volume);
        await _backgroundPlayer.play(UrlSource(story.backgroundMusicUrl!));
        _logger.d('Playing background music at volume $volume: ${story.backgroundMusicUrl}');
      } else {
        _logger.w('No background music URL available for story');
      }
    } catch (e) {
      _logger.e('Error playing background music', error: e);
    }
  }

  /// Start background music intro at initial volume

  /// Pause both audio streams
  Future<void> _pausePlayback() async {
    setState(() {
      _playbackState = PlaybackState.paused;
    });
    
    // Cancel any pending timers
    _narrationStartTimer?.cancel();
    _outroFadeTimer?.cancel();
    
    // Pause both audio streams
    await _audioPlayer.pause();
    await _backgroundPlayer.pause();
    
    _logger.d('Playback paused');
  }
  
  /// Resume playback from pause
  Future<void> _resumePlayback() async {
    setState(() {
      _playbackState = PlaybackState.playing;
    });
    
    // Resume background music if enabled
    if (_backgroundMusicEnabled) {
      await _backgroundPlayer.resume();
    }
    
    // Resume narration if it had started
    if (_hasStartedNarration) {
      await _audioPlayer.resume();
    } else {
      // If narration hadn't started yet, reschedule it
      final remainingIntroTime = _timeline.introLength - _currentPosition;
      if (remainingIntroTime > Duration.zero) {
        _narrationStartTimer = Timer(remainingIntroTime, () async {
          if (mounted && _playbackState == PlaybackState.playing) {
            await _audioPlayer.resume();
            _hasStartedNarration = true;
          }
        });
      }
    }
    
    _logger.d('Playback resumed');
  }
  
  
  /// Stop playback and clean up timers
  Future<void> _stopPlayback() async {
    // Cancel any pending timers
    _narrationStartTimer?.cancel();
    _outroFadeTimer?.cancel();
    
    // Stop both audio streams
    await _audioPlayer.stop();
    await _backgroundPlayer.stop();
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

  Future<void> _stopAndResetStoryPlayback() async {
    try {
      _logger.d('Stopping and resetting story playback for music selection');
      
      // Fade out both audio streams smoothly
      await _fadeOutAndStop();
      
      // Reset playback state
      setState(() {
        _playbackState = PlaybackState.stopped;
        _hasStartedNarration = false;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });
      
      _logger.d('Story playback stopped and reset to initial state');
    } catch (e) {
      _logger.e('Error stopping and resetting story playback', error: e);
    }
  }

  /// Fade out both audio streams before stopping
  Future<void> _fadeOutAndStop() async {
    const int fadeSteps = 10;
    const int fadeDelayMs = 50; // 50ms per step = 500ms total fade
    
    try {
      // Get current volumes
      double currentNarrationVolume = 1.0; // Default narration volume
      double currentBackgroundVolume = _backgroundVolumeNarration;
      
      // Fade out both audio streams simultaneously
      for (int i = 0; i < fadeSteps; i++) {
        double fadeProgress = (i + 1) / fadeSteps;
        double newNarrationVolume = currentNarrationVolume * (1.0 - fadeProgress);
        double newBackgroundVolume = currentBackgroundVolume * (1.0 - fadeProgress);
        
        await _audioPlayer.setVolume(newNarrationVolume);
        await _backgroundPlayer.setVolume(newBackgroundVolume);
        
        await Future.delayed(Duration(milliseconds: fadeDelayMs));
      }
      
      // Stop both players after fade
      await _audioPlayer.stop();
      await _backgroundPlayer.stop();
      
      // Reset narration volume to default
      await _audioPlayer.setVolume(1.0);
      
    } catch (e) {
      // Fallback to immediate stop if fade fails
      _logger.w('Fade out failed, stopping immediately', error: e);
      await _audioPlayer.stop();
      await _backgroundPlayer.stop();
    }
  }

  /// Toggle favourite status for the current story
  Future<void> _toggleFavourite(Story story) async {
    try {
      _logger.d('Toggling favourite status for story: ${story.id}');
      
      final updatedStory = await StoryService.toggleStoryFavourite(
        story.id,
        !story.isFavourite,
      );
      
      // Real-time subscriptions will automatically update home screen with favorite status changes
      
      // Update local state
      setState(() {
        _updatedStory = updatedStory;
      });
      
      _logger.d('Successfully toggled story favourite status to: ${updatedStory.isFavourite}');
      
    } catch (e) {
      _logger.e('Failed to toggle favourite status', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show dialog when story has no audio URL
  void _showNoAudioDialog(Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Audio Not Available'),
        content: Text('This story doesn\'t have audio yet. Would you like to refresh and try again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _refreshStoryData();
            },
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMusicSelectionSheet(Story story) async {
    // Stop story playback and reset to initial state
    await _stopAndResetStoryPlayback();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MusicSelectionSheet(
        story: story,
        currentTrackFilename: _currentTrackFilename,
        onTrackSelected: (track) async {
          try {
            final updatedStory = await BackgroundMusicService.updateStoryBackgroundMusic(
              story.id,
              track.filename,
            );
            
            // Update local state with new track and story data
            setState(() {
              _currentTrackFilename = track.filename;
              _updatedStory = updatedStory; // Store the updated story data
            });
            
            _logger.d('Successfully updated story background music to: ${track.filename}');
            
          } catch (e) {
            _logger.e('Failed to update background music', error: e);
            rethrow;
          }
        },
      ),
    );
  }



}

/// Stateful widget for music selection bottom sheet
class _MusicSelectionSheet extends StatefulWidget {
  final Story story;
  final String? currentTrackFilename;
  final Future<void> Function(BackgroundMusicTrack) onTrackSelected;

  const _MusicSelectionSheet({
    required this.story,
    required this.currentTrackFilename,
    required this.onTrackSelected,
  });

  @override
  State<_MusicSelectionSheet> createState() => _MusicSelectionSheetState();
}

class _MusicSelectionSheetState extends State<_MusicSelectionSheet> {
  static final _logger = LoggingService.getLogger('MusicSelectionSheet');
  List<BackgroundMusicTrack> _availableTracks = [];
  String? _currentTrackFilename;
  bool _isLoadingTracks = true;
  bool _isSelectingTrack = false;
  
  // Preview playback state
  AudioPlayer? _previewPlayer;
  String? _currentlyPlayingTrack;
  bool _isPreviewPlaying = false;

  @override
  void initState() {
    super.initState();
    _updateCurrentTrackFromStory();
    _previewPlayer = AudioPlayer();
    _loadAvailableTracks();
  }
  
  @override
  void didUpdateWidget(_MusicSelectionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update current track if story changed
    if (oldWidget.story.backgroundMusicUrl != widget.story.backgroundMusicUrl) {
      _updateCurrentTrackFromStory();
    }
  }
  
  void _updateCurrentTrackFromStory() {
    // Extract filename from the story's background music URL if available
    if (widget.story.backgroundMusicUrl != null) {
      _currentTrackFilename = BackgroundMusicService.extractFilenameFromUrl(widget.story.backgroundMusicUrl);
      _logger.d('Story background music URL: ${widget.story.backgroundMusicUrl}');
      _logger.d('Extracted current track filename: $_currentTrackFilename');
    } else {
      _currentTrackFilename = widget.currentTrackFilename;
      _logger.d('Using passed current track filename: $_currentTrackFilename');
    }
  }

  @override
  void dispose() {
    _previewPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTracks() async {
    try {
      final response = await BackgroundMusicService.getBackgroundMusicTracks();
      if (mounted) {
        setState(() {
          _availableTracks = response.tracks;
          _isLoadingTracks = false;
        });
        
        // Debug: log all track filenames and current selection
        _logger.d('Loaded ${_availableTracks.length} tracks. Current selection: $_currentTrackFilename');
        for (var track in _availableTracks) {
          final isSelected = track.filename == _currentTrackFilename;
          _logger.d('Track: ${track.filename} - Selected: $isSelected');
        }
      }
    } catch (e) {
      _logger.e('Failed to load background music tracks', error: e);
      if (mounted) {
        setState(() {
          _isLoadingTracks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Choose Background Music',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: SvgPicture.asset(
                        'assets/icons/x.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(AppColors.grey600, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tracks list
              Expanded(
                child: _isLoadingTracks
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _availableTracks.isEmpty
                        ? _buildEmptyState()
                        : _buildTracksList(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/music.svg',
            width: 48,
            height: 48,
            colorFilter: const ColorFilter.mode(AppColors.grey400, BlendMode.srcIn),
          ),
          const SizedBox(height: 16),
          Text(
            'No music tracks available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _loadAvailableTracks(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _availableTracks.length,
      itemBuilder: (context, index) {
        final track = _availableTracks[index];
        final isSelected = track.filename == _currentTrackFilename;
        
        return _buildTrackTile(track, isSelected);
      },
    );
  }

  Widget _buildTrackTile(BackgroundMusicTrack track, bool isSelected) {
    final isCurrentlyPlaying = _currentlyPlayingTrack == track.filename && _isPreviewPlaying;
    final trackTitle = track.filename.replaceAll('.mp3', '');
    
    // Debug logging
    if (isSelected) {
      _logger.d('Track ${track.filename} is selected. Current: $_currentTrackFilename');
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.grey100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              track.coverImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/music.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(AppColors.grey500, BlendMode.srcIn),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          trackTitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/Pause button
            IconButton(
              onPressed: () => _togglePreviewPlayback(track),
              icon: SvgPicture.asset(
                isCurrentlyPlaying ? 'assets/icons/player-pause-filled.svg' : 'assets/icons/player-play-filled.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isCurrentlyPlaying ? AppColors.primary : AppColors.grey400, 
                  BlendMode.srcIn
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Selection/Check button
            GestureDetector(
              onTap: isSelected || _isSelectingTrack ? null : () => _selectTrack(track),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: isSelected ? AppColors.white : AppColors.grey400,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        onTap: isSelected || _isSelectingTrack ? null : () => _selectTrack(track),
      ),
    );
  }

  Future<void> _togglePreviewPlayback(BackgroundMusicTrack track) async {
    try {
      if (_currentlyPlayingTrack == track.filename && _isPreviewPlaying) {
        // Stop current track
        await _previewPlayer?.stop();
        setState(() {
          _isPreviewPlaying = false; 
          _currentlyPlayingTrack = null;
        });
      } else {
        // Stop any currently playing track
        if (_isPreviewPlaying) {
          await _previewPlayer?.stop();
        }
        
        // Play new track
        await _previewPlayer?.play(UrlSource(track.url));
        setState(() {
          _isPreviewPlaying = true;
          _currentlyPlayingTrack = track.filename;
        });
        
        // Set up completion listener to reset state
        _previewPlayer?.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPreviewPlaying = false;
              _currentlyPlayingTrack = null;
            });
          }
        });
      }
    } catch (e) {
      _logger.e('Failed to toggle preview playback', error: e);
    }
  }

  Future<void> _selectTrack(BackgroundMusicTrack track) async {
    try {
      _logger.d('Selecting background music track: ${track.filename}');
      
      // Stop preview playback if active
      if (_isPreviewPlaying) {
        await _previewPlayer?.stop();
        setState(() {
          _isPreviewPlaying = false;
          _currentlyPlayingTrack = null;
        });
      }
      
      // Show loading state
      setState(() {
        _isSelectingTrack = true;
        _currentTrackFilename = track.filename;
      });

      // Update story in backend
      await widget.onTrackSelected(track);
      
      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      _logger.e('Failed to select background music track', error: e);
      
      // Revert the selection
      if (mounted) {
        setState(() {
          _currentTrackFilename = widget.currentTrackFilename;
          _isSelectingTrack = false;
        });
      }
      rethrow; // Re-throw to let parent handle the error
    }
  }
}
