import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../models/input_format.dart';
import '../../widgets/responsive_wrapper.dart';

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

  @override
  void initState() {
    super.initState();
    // Get arguments from route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _currentFormat = args['format'] as InputFormat;
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
        child: Column(
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
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
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
    return Container(
      width: 200,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'upload',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDictateButton() {
    return Container(
      width: 200,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'dictate',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
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
              hintStyle: TextStyle(color: Colors.grey),
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 200,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'submit',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildImageInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choose how to add your image',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _buildImageButton(
          icon: FontAwesomeIcons.camera,
          label: 'Take Photo',
          onPressed: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(width: 20),
        _buildImageButton(
          icon: FontAwesomeIcons.image,
          label: 'Select from Gallery',
          onPressed: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Record your voice to create a story',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _startRecording,
              borderRadius: BorderRadius.circular(60),
              child: const Icon(
                FontAwesomeIcons.microphone,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tap to start recording',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textGrey,
          ),
        ),
      ],
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
        _navigateToProcessing();
        // TODO: Process image with backend
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

  void _startRecording() {
    _navigateToProcessing();
    // TODO: Implement audio recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio recording will be implemented soon!')),
    );
  }

  void _createStoryFromText() {
    if (_textController.text.trim().isNotEmpty) {
      _navigateToProcessing();
      // TODO: Process text with backend
    }
  }

  void _navigateToProcessing() {
    Navigator.pushReplacementNamed(context, '/processing');
  }
}