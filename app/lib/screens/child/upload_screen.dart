import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../models/input_format.dart';
import '../../widgets/responsive_wrapper.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late InputFormat _currentFormat;
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
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: EdgeInsets.all(ResponsiveBreakpoints.getResponsivePadding(context)),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildMascot(),
                  const SizedBox(height: 40),
                  _buildFormatToggle(),
                  const SizedBox(height: 40),
                  Expanded(
                    child: _buildInputArea(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const FaIcon(
            FontAwesomeIcons.xmark,
            color: AppColors.textDark,
            size: 24,
          ),
        ),
        const Spacer(),
        Text(
          'Create Story',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48), // Balance the close button
      ],
    );
  }

  Widget _buildMascot() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Center(
        child: SvgPicture.asset(
          AppAssets.miraReady,
          width: 80,
          height: 80,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildFormatToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleIcon(FontAwesomeIcons.image, FontAwesomeIcons.solidImage, InputFormat.image, 'Image'),
        const SizedBox(width: 16),
        _buildToggleIcon(FontAwesomeIcons.microphone, FontAwesomeIcons.microphone, InputFormat.audio, 'Audio'),
        const SizedBox(width: 16),
        _buildToggleIcon(FontAwesomeIcons.penToSquare, FontAwesomeIcons.solidPenToSquare, InputFormat.text, 'Text'),
      ],
    );
  }

  Widget _buildToggleIcon(IconData regularIcon, IconData solidIcon, InputFormat format, String label) {
    final isSelected = _currentFormat == format;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFormat = format;
        });
      },
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: FaIcon(
              isSelected ? solidIcon : regularIcon,
              key: ValueKey(isSelected),
              color: isSelected ? AppColors.primary : AppColors.textGrey,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    switch (_currentFormat) {
      case InputFormat.image:
        return _buildImageInput();
      case InputFormat.audio:
        return _buildAudioInput();
      case InputFormat.text:
        return _buildTextInput();
    }
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

  Widget _buildTextInput() {
    return Column(
      children: [
        Text(
          'Write your story idea',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Once upon a time...',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _textController.text.trim().isNotEmpty ? _createStoryFromText : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Create Story',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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