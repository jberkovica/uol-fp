import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
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

class _UploadScreenState extends State<UploadScreen> {
  InputFormat _currentFormat = InputFormat.image; // Initialize with default value
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AIStoryService _aiService = AIStoryService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final _logger = LoggingService.getLogger('UploadScreen');
  Kid? _selectedKid;
  bool _isProcessing = false;
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _showSubmitButton = false;

  @override
  void initState() {
    super.initState();
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
    _textController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
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
          strokeIcon: 'assets/icons/photo.svg',
          solidIcon: 'assets/icons/photo-filled.svg',
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
          strokeIcon: 'assets/icons/file-description.svg',
          solidIcon: 'assets/icons/file-description-filled.svg',
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
      onPressed: _showImageSourceOptions,
      child: Text(AppLocalizations.of(context)!.upload),
    );
  }
  
  Widget _buildDictateButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recording indicator with timer
        if (_isRecording)
          Container(
            width: 200,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/microphone.svg',
                      width: 24.0,
                      height: 24.0,
                      colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.recording,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_recordingDuration),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 20),
        
        // Record/Stop button
        if (!_showSubmitButton)
          FilledButton(
            onPressed: _isProcessing ? null : (_isRecording ? _stopRecording : _startRecording),
            style: FilledButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red : AppColors.primary,
            ),
            child: Text(_isRecording ? AppLocalizations.of(context)!.stopRecording : AppLocalizations.of(context)!.dictate),
          ),
        
        // Submit button (shown after recording stops)
        if (_showSubmitButton && !_isProcessing)
          FilledButton(
            onPressed: _submitAudioStory,
            child: Text(AppLocalizations.of(context)!.submit),
          ),
        
        // Processing indicator
        if (_isProcessing)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
      ],
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
                color: Colors.black.withOpacity(0.1),
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

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.textGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                'Select Image Source',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 24),

              // Camera option
              _buildSourceButton(
                iconPath: 'assets/icons/photo.svg', // Using camera icon from your SVG set
                label: 'Take Photo',
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              const SizedBox(height: 16),

              // Gallery option
              _buildSourceButton(
                iconPath: 'assets/icons/photo.svg',
                label: 'Choose from Gallery',
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 16),

              // Cancel button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppTheme.cancelButtonStyle,
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: AppTheme.modalActionButtonStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
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

      // Generate story using AI service with kid ID
      final Story story = await _aiService.generateStoryFromImageFile(imageFile, _selectedKid!.id);

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
    
    // Validate input
    if (textInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterText),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (textInput.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.textTooShort),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (textInput.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.textTooLong),
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
      // Generate story from text
      final story = await _aiService.generateStoryFromText(textInput, _selectedKid!.id);
      
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
        Navigator.push(
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

  /// Start audio recording with timer
  Future<void> _startRecording() async {
    try {
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

      // Start recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: 'story_audio.m4a');
      
      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _showSubmitButton = false;
      });

      _logger.i('Audio recording started');
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

  /// Stop audio recording and show submit button
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _recordingPath = path;
        _showSubmitButton = true;
      });

      _logger.i('Audio recording stopped, path: $path');
    } catch (e) {
      _logger.e('Failed to stop recording', error: e);
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _showSubmitButton = false;
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

  /// Submit audio for story generation
  Future<void> _submitAudioStory() async {
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
        Navigator.push(
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

}