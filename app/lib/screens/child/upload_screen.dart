import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../models/input_format.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/app_button.dart';
import '../../services/ai_story_service.dart';
import '../../models/story.dart';
import '../../models/kid.dart';
import './processing_screen.dart';

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
  Kid? _selectedKid;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Get arguments from route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _currentFormat = args['format'] as InputFormat;
          _selectedKid = args['kid'] as Kid?;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
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
            icon: const FaIcon(
              FontAwesomeIcons.xmark,
              color: AppColors.textDark,
              size: 24,
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
        _buildTopIcon(FontAwesomeIcons.image, InputFormat.image),
        const SizedBox(width: 40),
        _buildTopIcon(FontAwesomeIcons.microphone, InputFormat.audio),
        const SizedBox(width: 40),
        _buildTopIcon(FontAwesomeIcons.penToSquare, InputFormat.text),
      ],
    );
  }
  
  Widget _buildTopIcon(IconData icon, InputFormat format) {
    final isSelected = _currentFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _currentFormat = format),
      child: FaIcon(
        icon,
        size: 24,
        color: isSelected ? AppColors.primary : Colors.black54,
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
    return AppButton.pill(
      text: 'upload',
      onPressed: _showImageSourceOptions,
    );
  }
  
  Widget _buildDictateButton() {
    return AppButton.pill(
      text: 'dictate',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio recording will be implemented soon!'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
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
            decoration: const InputDecoration(
              hintText: 'write your idea here...',
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              hintStyle: TextStyle(color: AppColors.textGrey),
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 16, color: AppColors.textDark),
          ),
        ),
        const SizedBox(height: 20),
        AppButton.orange(
          text: 'submit',
          onPressed: () {
            if (_textController.text.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Text story generation will be implemented soon!'),
                  backgroundColor: AppColors.orange,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter some text first'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
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
                icon: FontAwesomeIcons.camera,
                label: 'Take Photo',
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              const SizedBox(height: 16),

              // Gallery option
              _buildSourceButton(
                icon: FontAwesomeIcons.image,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGrey,
                  foregroundColor: AppColors.textGrey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
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
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
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

      // Navigate to story display/playback screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/story-display',
          arguments: story,
        ).then((_) {
          // When returning from story display, pop back to home screen
          Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate story: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

}