import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/input_format.dart';
import '../../services/ai_story_service.dart';
import '../../services/auth_service.dart';
import '../../services/logging_service.dart';
import '../../models/story.dart';
import '../../models/kid.dart';
import './processing_screen.dart';
import './story_ready_screen.dart';
import '../../generated/app_localizations.dart';

// Custom clipper for angled ellipse curve - same as splash screen
class AngledEllipseClipper extends CustomClipper<Path> {
  final double screenWidth;
  final double screenHeight;

  AngledEllipseClipper({required this.screenWidth, required this.screenHeight});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Line to bottom right
    path.lineTo(size.width, size.height);
    
    // Line up the right side to start of curve
    path.lineTo(size.width, size.height * 0.4);
    
    // Create simple smooth curve to match design file
    // Single clean elliptical curve from right to left
    path.cubicTo(
      size.width * 0.75, size.height * 0.1,  // First control point
      size.width * 0.25, size.height * 0.1,  // Second control point
      0, size.height * 0.4,                  // End point
    );
    
    // Close the path
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with TickerProviderStateMixin {
  InputFormat _currentFormat = InputFormat.image; // Initialize with default value
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _transcribedTextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AIStoryService _aiService = AIStoryService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final _logger = LoggingService.getLogger('UploadScreen');
  Kid? _selectedKid;
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _isRecordingStopped = false; // New state for stopped recording
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _showSubmitButton = false;
  String? _currentStoryId;
  bool _isTranscribing = false;
  
  // Audio playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _currentPlaybackPosition = Duration.zero;
  Duration _totalAudioDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completionSubscription;
  
  // Real-time amplitude monitoring with smoothing
  Timer? _amplitudeTimer;
  List<double> _amplitudeHistory = [];
  double _currentAmplitude = 0.0;
  double _smoothedAmplitude = 0.0; // Smoothed amplitude for better visualization
  double _lastSignificantAmplitude = 0.0; // Track last significant change
  final int _maxAmplitudeHistory = 100; // Increased history for better waveform
  final double _amplitudeSmoothingFactor = 0.3; // Exponential moving average factor
  final double _amplitudeChangeThreshold = 0.05; // Minimum change to trigger UI update
  
  // Animation controllers for waveform
  late AnimationController _waveformController;
  late List<AnimationController> _barControllers;
  final int _waveformBars = 20;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers for waveform
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _barControllers = List.generate(_waveformBars, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (index * 50)),
        vsync: this,
      );
    });
    
    // Get arguments from route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _currentFormat = args['format'] as InputFormat? ?? InputFormat.image;
          _selectedKid = args['kid'] as Kid?;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cleanup temporary audio file when leaving screen
    _cleanupAudioFile();
    
    _textController.dispose();
    _transcribedTextController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    _waveformController.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary, // Yellow background
      body: SafeArea(
        child: Stack(
          children: [
            Column(
                children: [
                  // Header with close button
                  _buildHeader(),
                  
                  // Content area with padding only for top content
                  Expanded(
                    child: Column(
                      children: [
                        // Top section with padding
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              
                              // Icons at top
                              _buildTopIcons(),
                              
                              const SizedBox(height: 40),
                              
                              // Main action button/area in center
                              _buildMainAction(),
                              
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                        
                        // Bottom section with mascot - no horizontal padding
                        Expanded(
                          child: _buildMascotFace(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // Show ProcessingScreen overlay when processing
            if (_isProcessing)
              ProcessingScreen(
                showCloseButton: true,
                onClose: () {
                  setState(() {
                    _isProcessing = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Balance
          const SizedBox(), // Empty center
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: SvgPicture.asset(
              'assets/icons/x.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopIcon(
          strokeIcon: 'assets/icons/camera.svg',
          solidIcon: 'assets/icons/camera-filled.svg',
          format: InputFormat.image,
        ),
        const SizedBox(width: 30),
        _buildTopIcon(
          strokeIcon: 'assets/icons/microphone.svg',
          solidIcon: 'assets/icons/microphone-filled.svg',
          format: InputFormat.audio,
        ),
        const SizedBox(width: 30),
        _buildTopIcon(
          strokeIcon: 'assets/icons/align-justified.svg',
          solidIcon: 'assets/icons/align-justified.svg',
          format: InputFormat.text,
        ),
      ],
    );
  }
  
  Widget _buildTopIcon({
    required String strokeIcon,
    required String solidIcon,
    required InputFormat format,
  }) {
    final isSelected = _currentFormat == format;
    final color = isSelected ? AppColors.primary : Colors.black54;
    final iconPath = isSelected ? solidIcon : strokeIcon;
    
    return GestureDetector(
      onTap: () => setState(() => _currentFormat = format),
      child: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
  
  Widget _buildMascotFace() {
    final screenSize = MediaQuery.of(context).size;
    
    return SizedBox(
      height: screenSize.height * 0.3, // 30% of screen height
      child: Stack(
        children: [
          // Purple curved shape anchored to bottom - exact same as splash screen
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: AngledEllipseClipper(
                screenWidth: screenSize.width,
                screenHeight: screenSize.height,
              ),
              child: Container(
                height: screenSize.height * 0.5, // 50% of screen height
                decoration: const BoxDecoration(
                  color: AppColors.primary, // Purple color
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: screenSize.height * 0.05),
                    child: SvgPicture.asset(
                      'assets/images/face-1.svg',
                      width: 80,
                      height: 40,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction() {
    switch (_currentFormat) {
      case InputFormat.image:
        return _buildUploadButton();
      case InputFormat.audio:
        return _buildDictateButton();
      case InputFormat.text:
        return _buildTextInput();
    }
  }
  
  Widget _buildUploadButton() {
    return FilledButton(
      onPressed: _pickImageDirectly,
      child: Text(AppLocalizations.of(context)!.upload),
    );
  }
  
  Widget _buildDictateButton() {
    // State 4: Review State (after recording with transcribed text)
    if (_transcribedTextController.text.isNotEmpty && !_isProcessing && !_isTranscribing) {
      return _buildReviewState();
    }
    
    // State 3: Stopped State (recorded but not transcribed yet) or Transcribing State
    if (_isRecordingStopped || _isTranscribing) {
      return _buildStoppedState();
    }
    
    // State 2: Recording State (currently recording)
    if (_isRecording) {
      return _buildRecordingState();
    }
    
    // State 1: Initial State - show audio controls in violet container
    return _buildInitialAudioState();
  }
  
  Widget _buildInitialAudioState() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Microphone icon hint
          Text(
            AppLocalizations.of(context)!.tapToStartRecording,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          
          // Mic button to start recording
          GestureDetector(
            onTap: _isProcessing ? null : _startRecording,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/microphone.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordingState() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer at top
            Text(
              _formatDuration(_recordingDuration),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Audio waveform when recording
            _buildWaveform(),
            
            const SizedBox(height: 20),
            
            // Pause button with no background
            IconButton(
              onPressed: _stopRecording,
              iconSize: 28,
              icon: SvgPicture.asset(
                'assets/icons/player-pause-filled.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              tooltip: AppLocalizations.of(context)!.pauseRecording,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoppedState() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer at top
            Text(
              _formatDuration(_recordingDuration),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Show different content based on state
            if (_isTranscribing)
              SizedBox(
                height: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.transcribingAudio,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildAudioVisualization(),
            
            const SizedBox(height: 20),
            
            // Control buttons (only show when not transcribing)
            if (!_isTranscribing)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Start Over button
                  IconButton(
                    onPressed: _restartRecording,
                    icon: SvgPicture.asset(
                      'assets/icons/refresh.svg',
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    tooltip: AppLocalizations.of(context)!.startOver,
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Play/Pause button
                  IconButton(
                    onPressed: _toggleAudioPlayback,
                    icon: SvgPicture.asset(
                      _isPlayingAudio ? 'assets/icons/player-pause-filled.svg' : 'assets/icons/player-play-filled.svg',
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    tooltip: _isPlayingAudio ? AppLocalizations.of(context)!.pauseAudio : AppLocalizations.of(context)!.playAudio,
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Submit button with check icon
                  IconButton(
                    onPressed: _continueToTranscription,
                    icon: SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    tooltip: AppLocalizations.of(context)!.submitForTranscription,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
      
  Widget _buildReviewState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 280,
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _transcribedTextController,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textDark,
              height: 1.4,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              hintText: 'Edit your transcribed text here...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGrey,
              ),
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.transparent,
              filled: false,
            ),
            // Remove selection color override to use clean white background
            selectionControls: MaterialTextSelectionControls(),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Button row with dictate restart, text mode, and submit options
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dictate again button
            TextButton.icon(
              onPressed: _isProcessing ? null : _restartDictation,
              icon: SvgPicture.asset(
                'assets/icons/microphone.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
              label: Text(AppLocalizations.of(context)!.dictateAgain),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Transfer to text mode
            TextButton.icon(
              onPressed: _isProcessing ? null : _transferToTextMode,
              icon: SvgPicture.asset(
                'assets/icons/typography.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
              label: Text(AppLocalizations.of(context)!.editAsText),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        FilledButton(
          onPressed: _isProcessing ? null : _submitAudioStory,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(AppLocalizations.of(context)!.submit),
        ),
      ],
    );
  }
  
  
  Widget _buildWaveform() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_waveformBars, (index) {
          // Use real-time amplitude data for waveform visualization
          double barHeight = 8.0; // Base height
          const maxHeight = 44.0;
          
          if (_amplitudeHistory.isNotEmpty) {
            // Enhanced mapping for better real-time visualization
            final totalSamples = _amplitudeHistory.length;
            final samplesPerBar = totalSamples / _waveformBars;
            
            // Calculate the range of samples this bar represents
            final startIndex = (index * samplesPerBar).floor();
            final endIndex = ((index + 1) * samplesPerBar).ceil().clamp(0, totalSamples);
            
            if (startIndex < endIndex && startIndex < totalSamples) {
              final sectionAmplitudes = _amplitudeHistory.sublist(startIndex, endIndex);
              
              // Use peak detection for real-time visualization (more responsive than RMS)
              if (sectionAmplitudes.isNotEmpty) {
                final peakAmplitude = sectionAmplitudes.reduce(max);
                final enhancedAmplitude = _enhanceAmplitudeForVisualization(peakAmplitude);
                barHeight = 8.0 + (enhancedAmplitude * (maxHeight - 8.0));
              }
            }
            
            // Debug logging for first bar only
            if (index == 0 && _isRecording && (_amplitudeHistory.length % 20) == 0) {
              // Waveform visualization active
            }
          } else {
            // Fallback to current amplitude for all bars when no history
            final enhancedAmplitude = _enhanceAmplitudeForVisualization(_currentAmplitude);
            barHeight = 8.0 + (enhancedAmplitude * (maxHeight - 8.0));
            
            if (index == 0 && _isRecording) {
              // Waveform fallback visualization
            }
          }
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150), // Slightly slower for smoother animation
            width: 3,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildTextInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 280,
          height: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.writeYourIdeaHere,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textGrey),
              contentPadding: EdgeInsets.zero,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isProcessing ? null : _generateStoryFromText,
          child: _isProcessing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(AppLocalizations.of(context)!.submit),
        ),
      ],
    );
  }

  Future<void> _pickImageDirectly() async {
    try {
      // Open native image picker with gallery as default, but camera will be available
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, // This opens the native picker with both options
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isProcessing = true;
        });
        await _generateStory(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToPickImage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isProcessing = true;
        });
        await _generateStory(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToPickImage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generateStory(XFile imageFile) async {
    try {
      // Use the selected kid's ID for story generation
      if (_selectedKid == null) {
        throw Exception('No kid profile selected');
      }

      _logger.i('Starting story generation from image for kid: ${_selectedKid!.id}');
      
      // Generate story using AI service with kid ID
      final Story story = await _aiService.generateStoryFromImageFile(imageFile, _selectedKid!.id);
      _logger.i('Story generated successfully from image: ${story.id}');

      // Real-time subscription will automatically update stories

      setState(() {
        _isProcessing = false;
      });

      // Navigate to story ready screen with appropriate approval mode
      if (mounted) {
        // Get current user's approval mode
        final approvalModeString = AuthService.instance.getUserApprovalMode();
        ApprovalMode approvalMode;
        switch (approvalModeString) {
          case 'app':
            approvalMode = ApprovalMode.app;
            break;
          case 'email':
            approvalMode = ApprovalMode.email;
            break;
          default:
            approvalMode = ApprovalMode.auto;
            break;
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryReadyScreen(
              story: story,
              approvalMode: approvalMode,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToGenerateStory(e.toString())),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Generate story from text input
  Future<void> _generateStoryFromText() async {
    final textInput = _textController.text.trim();
    
    // If we have a current story ID from transcription flow, use submitStoryText
    if (_currentStoryId != null) {
      // Validate input using unified validation
      final validationError = _validateTextInput(textInput);
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      setState(() {
        _isProcessing = true;
      });
      
      try {
        _logger.i('Submitting story text for story ID: $_currentStoryId, kid: ${_selectedKid!.id}');
        
        final story = await _aiService.submitStoryText(_currentStoryId!, textInput);
        _logger.i('Story text submitted successfully: ${story.id}');
        
        // Real-time subscription will automatically update stories
        
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          // Get current user's approval mode
          final approvalModeString = AuthService.instance.getUserApprovalMode();
          ApprovalMode approvalMode;
          switch (approvalModeString) {
            case 'app':
              approvalMode = ApprovalMode.app;
              break;
            case 'email':
              approvalMode = ApprovalMode.email;
              break;
            default:
              approvalMode = ApprovalMode.auto;
              break;
          }
          
          // Navigate to story ready screen
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                StoryReadyScreen(
                  story: story,
                  approvalMode: approvalMode,
                ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
                  child: child,
                );
              },
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit story text: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      return;
    }
    
    // Original text input flow (no story ID)
    // Validate input using unified validation
    final validationError = _validateTextInput(textInput);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedKid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectChild),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      _logger.i('Starting story generation from text for kid: ${_selectedKid!.id}');
      
      // Generate story from text
      final story = await _aiService.generateStoryFromText(textInput, _selectedKid!.id);
      _logger.i('Story generated successfully: ${story.id}');
      
      // Real-time subscription will automatically update stories
      
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        // Get current user's approval mode
        final approvalModeString = AuthService.instance.getUserApprovalMode();
        ApprovalMode approvalMode;
        switch (approvalModeString) {
          case 'app':
            approvalMode = ApprovalMode.app;
            break;
          case 'email':
            approvalMode = ApprovalMode.email;
            break;
          default:
            approvalMode = ApprovalMode.auto;
            break;
        }
        
        // Navigate to story ready screen
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              StoryReadyScreen(
                story: story,
                approvalMode: approvalMode,
              ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToGenerateStory(e.toString())),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Start audio recording with timer and waveform animation
  Future<void> _startRecording() async {
    try {
      // Check if kid is selected
      if (_selectedKid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSelectChild),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.microphonePermissionRequired),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Check if encoder is supported
      if (!await _audioRecorder.hasPermission()) {
        _logger.w('Audio recording permission not granted');
        return;
      }

      // Initiate voice story first
      try {
        final storyId = await _aiService.initiateVoiceStory(_selectedKid!.id);
        setState(() {
          _currentStoryId = storyId;
        });
        _logger.i('Voice story initiated: $storyId');
      } catch (e) {
        _logger.e('Failed to initiate story', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Unable to start recording session. Please check your connection and try again.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Start recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: 'story_audio.webm');
      
      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });
      
      // Start waveform animations and amplitude monitoring
      _startWaveformAnimation();
      _startAmplitudeMonitoring();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _showSubmitButton = false;
        _transcribedTextController.clear();
        _amplitudeHistory.clear(); // Clear previous amplitude data
      });

      _logger.i('Audio recording started with amplitude monitoring');
    } catch (e) {
      _logger.e('Failed to start recording', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToStartRecording}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  /// Start waveform animation with realistic audio simulation
  void _startWaveformAnimation() {
    _waveformController.repeat();
    
    // Create more realistic audio waveform pattern
    for (int i = 0; i < _barControllers.length; i++) {
      // Vary the animation duration for each bar
      final duration = Duration(milliseconds: 300 + (i % 3) * 100);
      
      Future.delayed(Duration(milliseconds: i * 30), () {
        if (_isRecording && mounted) {
          // Animate to random heights to simulate audio input
          _animateBar(i, duration);
        }
      });
    }
  }
  
  /// Animate individual bar with random heights
  void _animateBar(int index, Duration duration) {
    if (!_isRecording || !mounted) return;
    
    // Create more dynamic wave pattern
    final centerIndex = _waveformBars / 2;
    final distanceFromCenter = (index - centerIndex).abs() / centerIndex;
    final baseAmplitude = 1.0 - (distanceFromCenter * 0.6);
    
    // Add some randomness for realistic audio visualization
    final random = (DateTime.now().millisecondsSinceEpoch % 100) / 100;
    final targetValue = baseAmplitude * (0.3 + (0.7 * random));
    
    _barControllers[index].animateTo(
      targetValue,
      duration: duration,
      curve: Curves.easeInOut,
    ).then((_) {
      if (_isRecording && mounted) {
        // Continue animating with new random value
        _animateBar(index, Duration(milliseconds: 200 + (random * 200).toInt()));
      }
    });
  }
  
  /// Stop waveform animation
  void _stopWaveformAnimation() {
    _waveformController.stop();
    for (final controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  /// Start real-time amplitude monitoring during recording with reduced delay
  void _startAmplitudeMonitoring() {
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      try {
        final amplitude = await _audioRecorder.getAmplitude();
        
        // Convert dBFS to normalized value (0.0 to 1.0)
        // Professional recording standards:
        // - 0 dBFS: Maximum (clipping)
        // - -6 dBFS: Peak headroom target
        // - -20 to -24 dBFS: Recommended average recording level
        // - -60 to -90 dBFS: Typical noise floor
        // Mobile microphones typically range from -90 dBFS (quiet) to 0 dBFS (loud)
        
        // Use a practical range for visualization that adapts to different scenarios
        const double minDB = -60.0; // Below this is essentially silence/noise
        const double maxDB = -6.0;  // Target peak level (leaving headroom)
        const double range = maxDB - minDB;
        
        // Calculate normalized amplitude with better scaling
        double normalizedAmplitude;
        if (amplitude.current <= minDB) {
          normalizedAmplitude = 0.0; // Silence/noise floor
        } else if (amplitude.current >= maxDB) {
          normalizedAmplitude = 1.0; // Peak level
        } else {
          // Linear mapping between minDB and maxDB
          normalizedAmplitude = (amplitude.current - minDB) / range;
        }
        
        // Apply a slight exponential curve for better visual response
        // This makes quiet sounds more visible while keeping loud sounds under control
        normalizedAmplitude = pow(normalizedAmplitude, 0.7).toDouble();
        
        // Apply exponential moving average for smoothing
        _smoothedAmplitude = (_amplitudeSmoothingFactor * normalizedAmplitude) + 
                           ((1 - _amplitudeSmoothingFactor) * _smoothedAmplitude);
        
        // Only update UI if amplitude change is significant to reduce unnecessary redraws
        final amplitudeChange = (_smoothedAmplitude - _lastSignificantAmplitude).abs();
        if (amplitudeChange > _amplitudeChangeThreshold || _amplitudeHistory.isEmpty) {
          // Amplitude monitoring active
          
          setState(() {
            _currentAmplitude = _smoothedAmplitude.clamp(0.0, 1.0);
            _amplitudeHistory.add(_currentAmplitude);
            
            // Keep only the last N readings for performance
            if (_amplitudeHistory.length > _maxAmplitudeHistory) {
              _amplitudeHistory.removeAt(0);
            }
          });
          
          _lastSignificantAmplitude = _smoothedAmplitude;
        } else {
          // Still add to history without UI update for waveform continuity
          _amplitudeHistory.add(_smoothedAmplitude.clamp(0.0, 1.0));
          if (_amplitudeHistory.length > _maxAmplitudeHistory) {
            _amplitudeHistory.removeAt(0);
          }
        }
        
        // History maintained at optimal length
      } catch (e) {
        _logger.w('Failed to get amplitude: $e');
        // Add some fallback amplitude for testing with smoothing
        const fallbackAmplitude = 0.1; // Lower fallback for silence
        _smoothedAmplitude = (_amplitudeSmoothingFactor * fallbackAmplitude) + 
                           ((1 - _amplitudeSmoothingFactor) * _smoothedAmplitude);
        
        setState(() {
          _currentAmplitude = _smoothedAmplitude.clamp(0.0, 1.0);
          _amplitudeHistory.add(_currentAmplitude);
          if (_amplitudeHistory.length > _maxAmplitudeHistory) {
            _amplitudeHistory.removeAt(0);
          }
        });
      }
    });
  }

  /// Stop amplitude monitoring
  void _stopAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }
  
  
  /// Restart recording from beginning
  Future<void> _restartRecording() async {
    try {
      // Cleanup old audio file before restarting
      await _cleanupAudioFile();
      
      // Reset state immediately for better UX
      setState(() {
        _isRecording = false;
        _isRecordingStopped = false;
        _isPlayingAudio = false;
        _recordingDuration = Duration.zero;
        _recordingPath = null;
        _showSubmitButton = false;
        _transcribedTextController.clear();
      });
      
      // Stop current recording, timers, and amplitude monitoring
      _recordingTimer?.cancel();
      _stopWaveformAnimation();
      _stopAmplitudeMonitoring();
      await _audioRecorder.stop();
      
      // Start new recording immediately
      await _startRecording();
      
      _logger.i('Audio recording restarted');
    } catch (e) {
      _logger.e('Failed to restart recording', error: e);
      setState(() {
        _isRecording = false;
        _isRecordingStopped = false;
      });
    }
  }

  /// Stop audio recording and show stopped state
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      _stopWaveformAnimation();
      _stopAmplitudeMonitoring();
      
      setState(() {
        _isRecording = false;
        _recordingPath = path;
        _isRecordingStopped = true;
      });

      _logger.i('Audio recording stopped, path: $path');
      // User can now choose to continue to transcription or start again
    } catch (e) {
      _logger.e('Failed to stop recording', error: e);
      _recordingTimer?.cancel();
      _stopWaveformAnimation();
      setState(() {
        _isRecording = false;
        _showSubmitButton = false;
        _isTranscribing = false;
        _transcribedTextController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToStopRecording}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Continue from stopped recording state to transcription
  Future<void> _continueToTranscription() async {
    if (_recordingPath == null || _currentStoryId == null) {
      _logger.e('No recording path or story ID available for transcription');
      return;
    }

    setState(() {
      _isRecordingStopped = false;
      _isTranscribing = true;
    });

    try {
      final transcribedText = await _aiService.transcribeAudio(_currentStoryId!, _recordingPath!);
      
      // Cleanup temporary audio file after successful transcription
      await _cleanupAudioFile();
      
      // Switch to text mode with transcribed text instead of staying in audio format
      setState(() {
        _currentFormat = InputFormat.text; // Switch to text mode
        _textController.text = transcribedText; // Place text in regular text input
        
        // Clear all audio-related state
        _isTranscribing = false;
        _isRecording = false;
        _isRecordingStopped = false;
        _isPlayingAudio = false;
        _showSubmitButton = false;
        _transcribedTextController.clear();
        _recordingPath = null;
        _currentStoryId = null;
        _recordingDuration = Duration.zero;
        
        // Clear amplitude history
        _amplitudeHistory.clear();
        _currentAmplitude = 0.0;
        _smoothedAmplitude = 0.0;
        _lastSignificantAmplitude = 0.0;
      });
      
      _logger.i('Audio transcribed and switched to text mode: ${transcribedText.length} characters');
    } catch (e) {
      _logger.e('Failed to transcribe audio', error: e);
      setState(() {
        _isTranscribing = false;
        _isRecordingStopped = true; // Go back to stopped state
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not understand the audio. Please try recording again or use text input instead.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.switchToText,
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _currentFormat = InputFormat.text;
                  // Clear audio state
                  _isRecording = false;
                  _isRecordingStopped = false;
                  _showSubmitButton = false;
                  _transcribedTextController.clear();
                  _currentStoryId = null;
                });
              },
            ),
          ),
        );
      }
    }
  }

  /// Submit audio for story generation using new transcription flow
  Future<void> _submitAudioStory() async {
    // If we have transcribed text, use it to generate story
    if (_transcribedTextController.text.isNotEmpty && _currentStoryId != null) {
      final textInput = _transcribedTextController.text.trim();
      
      // Validate transcribed text
      final validationError = _validateTextInput(textInput);
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      setState(() {
        _isProcessing = true;
      });
      
      try {
        final story = await _aiService.submitStoryText(_currentStoryId!, textInput);
        
        // Cleanup temporary audio file after successful story submission
        await _cleanupAudioFile();
        
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          // Get current user's approval mode
          final approvalModeString = AuthService.instance.getUserApprovalMode();
          ApprovalMode approvalMode;
          switch (approvalModeString) {
            case 'app':
              approvalMode = ApprovalMode.app;
              break;
            case 'email':
              approvalMode = ApprovalMode.email;
              break;
            default:
              approvalMode = ApprovalMode.auto;
              break;
          }
          
          // Navigate to story ready screen
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                StoryReadyScreen(
                  story: story,
                  approvalMode: approvalMode,
                ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
                  child: child,
                );
              },
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Something went wrong while creating your story. Please try again or contact support if the problem continues.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      return;
    }
    
    // Fallback to old flow if no transcribed text
    if (_recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noRecordingAvailable),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _showSubmitButton = false;
    });
    
    await _generateStoryFromAudio(_recordingPath!);
  }

  /// Generate story from audio recording
  Future<void> _generateStoryFromAudio(String audioPath) async {
    if (_selectedKid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectChild),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Generate story from audio file
      final story = await _aiService.generateStoryFromAudio(audioPath, _selectedKid!.id);
      
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        // Get current user's approval mode
        final approvalModeString = AuthService.instance.getUserApprovalMode();
        ApprovalMode approvalMode;
        switch (approvalModeString) {
          case 'app':
            approvalMode = ApprovalMode.app;
            break;
          case 'email':
            approvalMode = ApprovalMode.email;
            break;
          default:
            approvalMode = ApprovalMode.auto;
            break;
        }
        
        // Navigate to story ready screen
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              StoryReadyScreen(
                story: story,
                approvalMode: approvalMode,
              ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      _logger.e('Failed to generate story from audio', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate story: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Format duration for display (mm:ss)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Unified text validation logic
  String? _validateTextInput(String text) {
    if (text.isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterText;
    }
    if (text.length < 10) {
      return AppLocalizations.of(context)!.textTooShort;
    }
    if (text.length > 500) {
      return AppLocalizations.of(context)!.textTooLong;
    }
    return null; // No error
  }

  /// Build audio visualization for stopped recording with improved content representation
  Widget _buildAudioVisualization() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_waveformBars, (index) {
          // Use recorded amplitude data for static waveform visualization
          double normalizedHeight = 0.1; // Lower default for silence
          const baseHeight = 8.0;
          const maxHeight = 44.0;
          
          if (_amplitudeHistory.isNotEmpty) {
            // Improved content-aware mapping
            // Instead of simple linear mapping, use weighted distribution
            final totalSamples = _amplitudeHistory.length;
            final samplesPerBar = totalSamples / _waveformBars;
            
            // Calculate the range of samples this bar represents
            final startIndex = (index * samplesPerBar).floor();
            final endIndex = ((index + 1) * samplesPerBar).ceil().clamp(0, totalSamples);
            
            if (startIndex < endIndex && startIndex < totalSamples) {
              final sectionAmplitudes = _amplitudeHistory.sublist(startIndex, endIndex);
              
              // Use RMS (Root Mean Square) for better audio representation
              if (sectionAmplitudes.isNotEmpty) {
                final rms = sqrt(sectionAmplitudes.map((a) => a * a).reduce((a, b) => a + b) / sectionAmplitudes.length);
                
                // Apply additional scaling for better visual representation
                // Boost quiet sounds slightly and compress loud sounds
                normalizedHeight = _enhanceAmplitudeForVisualization(rms);
              }
            }
          }
          
          final height = baseHeight + (normalizedHeight * (maxHeight - baseHeight));
          
          // Calculate if this bar represents played or unplayed audio with content-aware progress
          bool isPlayed = false;
          if (_isPlayingAudio && _totalAudioDuration.inMilliseconds > 0) {
            final progressRatio = _currentPlaybackPosition.inMilliseconds / _totalAudioDuration.inMilliseconds;
            
            // Content-aware progress mapping: weight progress by actual audio content
            final contentWeightedProgress = _calculateContentWeightedProgress(progressRatio, index);
            isPlayed = contentWeightedProgress;
            
            // Debug logging for first few bars to ensure colors are updating
            if (index <= 2 && _isPlayingAudio) {
              // Playback progress visualization
            }
          }
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100), // Smooth color transition
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: isPlayed 
                  ? AppColors.white // Bright white for played sections
                  : AppColors.white.withValues(alpha: 0.3), // More transparent for better contrast
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
  
  /// Enhance amplitude for better visualization
  double _enhanceAmplitudeForVisualization(double amplitude) {
    // Apply logarithmic scaling for better visual representation
    // This makes quiet sounds more visible while keeping loud sounds under control
    if (amplitude <= 0.0) return 0.1; // Minimum visibility for silence
    
    // Apply gentle logarithmic curve
    final enhanced = pow(amplitude, 0.6).toDouble();
    
    // Ensure minimum visibility for any detected sound
    return max(0.1, enhanced);
  }
  
  /// Calculate content-weighted progress for more accurate playback visualization
  bool _calculateContentWeightedProgress(double progressRatio, int barIndex) {
    // For now, use simple time-based progress but with smoother transitions
    // In the future, this could be enhanced with actual audio analysis
    final totalBars = _waveformBars;
    final expectedPlayedBars = (progressRatio * totalBars);
    
    // Add smooth transition zone
    final smoothingZone = 0.5; // Half a bar for smooth transition
    return barIndex < (expectedPlayedBars - smoothingZone);
  }

  /// Toggle audio playback (play/pause)
  Future<void> _toggleAudioPlayback() async {
    if (_recordingPath == null) return;

    try {
      if (_isPlayingAudio) {
        // Pause audio
        await _audioPlayer.pause();
        setState(() {
          _isPlayingAudio = false;
        });
        _logger.i('Audio paused');
      } else {
        // Play audio
        await _audioPlayer.play(DeviceFileSource(_recordingPath!));
        setState(() {
          _isPlayingAudio = true;
          _currentPlaybackPosition = Duration.zero;
        });
        _logger.i('Audio playing');
        
        // Start position monitoring
        _startPlaybackPositionMonitoring();
      }
    } catch (e) {
      _logger.e('Error toggling audio playback', error: e);
      setState(() {
        _isPlayingAudio = false;
        _currentPlaybackPosition = Duration.zero;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Start monitoring playback position for waveform progress
  void _startPlaybackPositionMonitoring() {
    // Cancel existing subscriptions
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    
    // Get total duration first
    _audioPlayer.getDuration().then((duration) {
      if (duration != null) {
        setState(() {
          _totalAudioDuration = duration;
        });
        // Audio duration set
      } else {
        _logger.w('Could not get audio duration');
      }
    });

    // Monitor position changes
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _isPlayingAudio) {
        setState(() {
          _currentPlaybackPosition = position;
        });
        // Playback position updated
      }
    });
    
    // Listen for completion
    _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _currentPlaybackPosition = Duration.zero;
        });
        // Audio playback completed
      }
    });
  }

  /// Restart dictation from review state
  Future<void> _restartDictation() async {
    try {
      // Cleanup current audio file before restarting
      await _cleanupAudioFile();
      
      // Clear current state
      setState(() {
        _transcribedTextController.clear();
        _recordingPath = null;
        _currentStoryId = null;
        _isProcessing = false;
        _showSubmitButton = false;
      });
      
      // Initiate new voice story
      if (_selectedKid != null) {
        final storyId = await _aiService.initiateVoiceStory(_selectedKid!.id);
        setState(() {
          _currentStoryId = storyId;
        });
        
        // Start recording
        await _startRecording();
        _logger.i('Restarted dictation with new story ID: $storyId');
      }
    } catch (e) {
      _logger.e('Failed to restart dictation', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restart dictation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Transfer transcribed text to text input mode
  void _transferToTextMode() {
    // Transfer the transcribed text to text controller
    _textController.text = _transcribedTextController.text;
    
    // Cleanup audio file before switching modes
    _cleanupAudioFile();
    
    // Switch to text input mode
    setState(() {
      _currentFormat = InputFormat.text;
      // Clear audio-related state
      _recordingPath = null;
      _currentStoryId = null;
      _isRecording = false;
      _isRecordingStopped = false;
      _isPlayingAudio = false;
      _isTranscribing = false;
      _showSubmitButton = false;
      _transcribedTextController.clear();
    });
    
    _logger.i('Transferred to text mode with transcribed content');
  }

  /// Cleanup temporary audio file
  Future<void> _cleanupAudioFile() async {
    if (_recordingPath == null) return;

    try {
      // Stop audio playback if running
      if (_isPlayingAudio) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingAudio = false;
        });
      }

      // On web, recording path is a blob URL that doesn't need manual cleanup
      // On mobile, it's a file path that we can delete
      if (!_recordingPath!.startsWith('blob:')) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Temporary audio file cleaned up: $_recordingPath');
        } else {
          _logger.w('Audio file not found for cleanup: $_recordingPath');
        }
      } else {
        _logger.i('Web blob URL cleanup not required: $_recordingPath');
      }
    } catch (e) {
      _logger.e('Failed to cleanup audio file', error: e);
      // Don't throw - cleanup failure shouldn't break the app
    } finally {
      // Clear the path reference and reset playback state
      _recordingPath = null;
      _currentPlaybackPosition = Duration.zero;
      _totalAudioDuration = Duration.zero;
      _amplitudeHistory.clear();
    }
  }

}