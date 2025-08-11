import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/kid.dart';
import '../../services/kid_service.dart';
import '../../constants/kid_profile_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../generated/app_localizations.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/profile_avatar.dart';

class KidProfileEditScreen extends StatefulWidget {
  final Kid kid;

  const KidProfileEditScreen({
    super.key,
    required this.kid,
  });

  @override
  State<KidProfileEditScreen> createState() => _KidProfileEditScreenState();
}

class _KidProfileEditScreenState extends State<KidProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _appearanceController;
  
  double _scrollOffset = 0.0;
  int _selectedAge = 5; // Now required field
  String? _selectedGender;
  String _selectedAvatarType = 'profile1';
  String? _appearanceMethod;
  List<String> _selectedGenres = [];
  String _preferredLanguage = 'en'; // Will be initialized from kid data
  
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isExtractingAppearance = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.kid.name);
    _notesController = TextEditingController(text: widget.kid.parentNotes ?? '');
    _appearanceController = TextEditingController(text: widget.kid.appearanceDescription ?? '');
    
    _selectedAge = widget.kid.age;
    _selectedGender = widget.kid.gender;
    _selectedAvatarType = widget.kid.avatarType;
    _appearanceMethod = widget.kid.appearanceMethod;
    _selectedGenres = List.from(widget.kid.favoriteGenres);
    _preferredLanguage = widget.kid.preferredLanguage;
    
    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
    _appearanceController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _onSelectionChanged() {
    _onFieldChanged();
  }

  Future<void> _pickAndExtractFromPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isExtractingAppearance = true;
      });

      // Convert image to base64 for API call
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call appearance extraction API
      final extractedDescription = await _extractAppearanceFromImage(
        base64Image,
        widget.kid.name,
        _selectedAge,
      );

      // Populate the text field with extracted description
      if (mounted && extractedDescription != null) {
        setState(() {
          _appearanceController.text = extractedDescription;
          _appearanceMethod = 'photo';
        });
        _onFieldChanged();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appearance extracted! You can review and edit the description below.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extract appearance: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingAppearance = false;
        });
      }
    }
  }

  Future<String?> _extractAppearanceFromImage(
    String base64Image,
    String kidName,
    int age,
  ) async {
    try {
      final uri = Uri.parse('${KidService.baseUrl}/kids/extract-appearance');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_data': base64Image,
          'kid_name': kidName,
          'age': age,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['description'] as String;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to extract appearance');
      }
    } catch (e) {
      throw Exception('Failed to extract appearance from photo: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _appearanceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterName),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Optimistic update - update locally first
      final updatedKid = widget.kid.copyWith(
        name: _nameController.text.trim(),
        age: _selectedAge,
        avatarType: _selectedAvatarType,
        appearanceMethod: _appearanceMethod,
        appearanceDescription: _appearanceController.text.trim().isEmpty 
            ? null 
            : _appearanceController.text.trim(),
        favoriteGenres: _selectedGenres,
        parentNotes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        preferredLanguage: _preferredLanguage,
      );

      // Update backend
      await KidService.updateKid(
        kidId: widget.kid.id,
        name: _nameController.text.trim(),
        age: _selectedAge,
        gender: _selectedGender,
        avatarType: _selectedAvatarType,
        appearanceMethod: _appearanceMethod,
        appearanceDescription: _appearanceController.text.trim().isEmpty 
            ? null 
            : _appearanceController.text.trim(),
        favoriteGenres: _selectedGenres,
        parentNotes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        preferredLanguage: _preferredLanguage,
      );

      // Return updated kid to parent screen
      if (mounted) {
        Navigator.of(context).pop(updatedKid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUpdateProfile(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Purple background
          Container(color: AppColors.primary),
          
          // Header content
          SafeArea(
            child: _buildHeader(),
          ),
          
          // Scrollable white content with parallax
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
                    SizedBox(height: (160 + (-_scrollOffset * 0.5)).clamp(80, 160)),
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ),
          
          // Back button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: ResponsiveBreakpoints.getResponsivePadding(context),
                top: 20,
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: SvgPicture.asset(
                  'assets/icons/arrow-left.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _hasChanges
          ? Container(
              margin: EdgeInsets.only(
                bottom: ResponsiveBreakpoints.getResponsivePadding(context),
              ),
              child: FloatingActionButton.extended(
                onPressed: _isLoading ? null : _saveChanges,
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textDark,
                elevation: 0,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textDark),
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/icons/copy-check.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                      ),
                label: Text(
                  AppLocalizations.of(context)!.saveChanges,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final horizontalPadding = ResponsiveBreakpoints.getResponsivePadding(context);
    
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width > 1200 ? 1200 : double.infinity,
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: EdgeInsets.fromLTRB(horizontalPadding, 60, horizontalPadding, 40),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.editProfile,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.kid.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints(minHeight: 800),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.getGlobalPadding(context),
            40,
            AppTheme.getGlobalPadding(context),
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildAppearanceSection(),
              const SizedBox(height: 24),
              _buildPersonalitySection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.basicInformation,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        
        // Name field
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey, width: 1),
          ),
          child: TextField(
            controller: _nameController,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterChildName,
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textGrey,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SvgPicture.asset(
                  'assets/icons/user-filled.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(AppColors.textGrey, BlendMode.srcIn),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        Text(
          'Age',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildAgeSelector(),
        
        const SizedBox(height: 24),
        Text(
          'Gender',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        _buildGenderSelector(),
        
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.chooseAvatar,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildAvatarSelector(),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.appearanceOptionalSection,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.appearanceDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 24),
        
        // Appearance method selector
        Text(
          AppLocalizations.of(context)!.appearanceMethodQuestion,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildAppearanceMethodSelector(),
        
        const SizedBox(height: 24),
        
        // Appearance description field (always shown for now, photo upload to be added later)
        _buildAppearanceDescriptionField(),
      ],
    );
  }

  Widget _buildPersonalitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.storyPreferencesOptional,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        
        Text(
          'Preferred Language',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildLanguageSelector(),
        
        const SizedBox(height: 24),
        Text(
          'Favorite Story Types',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildGenreSelector(),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.parentNotesOptional,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Add special context for stories: hobbies, pets, siblings, interests, etc.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey, width: 1),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.addSpecialNotesFor(widget.kid.name),
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textGrey,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(10, (index) {
        final age = index + 3;
        final isSelected = _selectedAge == age;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAge = age;
            });
            _onSelectionChanged();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightGrey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                age.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGenderSelector() {
    final l10n = AppLocalizations.of(context);
    final options = [
      {'value': 'boy', 'label': l10n?.boy ?? 'Boy'},
      {'value': 'girl', 'label': l10n?.girl ?? 'Girl'},
      {'value': 'other', 'label': l10n?.preferNotToSay ?? 'Prefer not to say'},
    ];
    
    return Row(
      children: options.map((option) {
        final isSelected = _selectedGender == option['value'];
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option['value'] != 'other' ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = option['value'] as String;
                });
                _onSelectionChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.lightGrey,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    option['label'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvatarSelector() {
    const avatarTypes = ['profile1', 'profile2', 'profile3', 'profile4'];
    
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: avatarTypes.length,
        itemBuilder: (context, index) {
          final avatarType = avatarTypes[index];
          final isSelected = _selectedAvatarType == avatarType;
          
          return Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatarType = avatarType;
                });
                _onSelectionChanged();
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.lightGrey,
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: ProfileAvatar(
                    radius: 47,
                    profileType: ProfileAvatar.fromString(avatarType),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppearanceMethodSelector() {
    final methods = [
      {'key': 'manual', 'label': AppLocalizations.of(context)!.describeInWords, 'icon': 'assets/icons/pencil-plus.svg'},
      {'key': 'photo', 'label': AppLocalizations.of(context)!.uploadPhoto, 'icon': 'assets/icons/camera-filled.svg'},
    ];
    
    return Column(
      children: methods.map((method) {
        final isSelected = _appearanceMethod == method['key'];
        final isPhoto = method['key'] == 'photo';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () async {
              if (isPhoto) {
                // Handle photo upload
                await _pickAndExtractFromPhoto();
              } else {
                // Handle manual method
                setState(() {
                  _appearanceMethod = isSelected ? null : method['key'] as String;
                });
                _onSelectionChanged();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.lightGrey,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  if (_isExtractingAppearance && isPhoto)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  else
                    SvgPicture.asset(
                      method['icon'] as String,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isSelected ? AppColors.primary : AppColors.textDark,
                        BlendMode.srcIn,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isExtractingAppearance && isPhoto 
                              ? 'Extracting appearance...' 
                              : method['label'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (isPhoto && !_isExtractingAppearance)
                          Text(
                            AppLocalizations.of(context)!.aiWillAnalyzePhoto,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected && !_isExtractingAppearance)
                    SvgPicture.asset(
                      'assets/icons/circle-check-filled.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAppearanceDescriptionField() {
    final isFromPhoto = _appearanceMethod == 'photo' && _appearanceController.text.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFromPhoto) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/circle-check-filled.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI extracted this description from your photo. Feel free to review and edit it.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey, width: 1),
          ),
          child: TextField(
            controller: _appearanceController,
            maxLines: 3,
            maxLength: 500,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: _appearanceMethod == 'photo' 
                  ? 'Upload a photo above to auto-generate description, or type manually'
                  : AppLocalizations.of(context)!.appearanceExamplePlaceholder,
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textGrey,
              ),
              helperText: isFromPhoto 
                  ? 'You can edit this AI-generated description to make it more personal.'
                  : AppLocalizations.of(context)!.appearanceHelperText,
              helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textGrey,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'ru', 'name': 'Russian'},
      {'code': 'lv', 'name': 'Latvian'},
      {'code': 'es', 'name': 'Spanish'},
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages.map((lang) {
        final isSelected = _preferredLanguage == lang['code'];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _preferredLanguage = lang['code'] as String;
            });
            _onSelectionChanged();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightGrey,
                width: 2,
              ),
            ),
            child: Text(
              lang['name'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenreSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KidProfileConstants.storyGenres.map((genre) {
        final isSelected = _selectedGenres.contains(genre);
        final displayName = _getLocalizedGenreName(genre);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedGenres.remove(genre);
              } else {
                _selectedGenres.add(genre);
              }
            });
            _onSelectionChanged();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.secondary : AppColors.lightGrey,
                width: 2,
              ),
            ),
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.textDark : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getLocalizedGenreName(String genre) {
    final l10n = AppLocalizations.of(context)!;
    switch (genre) {
      case 'adventure':
        return l10n.genreAdventure;
      case 'fantasy':
        return l10n.genreFantasy;
      case 'friendship':
        return l10n.genreFriendship;
      case 'family':
        return l10n.genreFamily;
      case 'animals':
        return l10n.genreAnimals;
      case 'magic':
        return l10n.genreMagic;
      case 'space':
        return l10n.genreSpace;
      case 'underwater':
        return l10n.genreUnderwater;
      case 'forest':
        return l10n.genreForest;
      case 'fairy_tale':
        return l10n.genreFairyTale;
      case 'superhero':
        return l10n.genreSuperhero;
      case 'dinosaurs':
        return l10n.genreDinosaurs;
      case 'pirates':
        return l10n.genrePirates;
      case 'princess':
        return l10n.genrePrincess;
      case 'dragons':
        return l10n.genreDragons;
      case 'robots':
        return l10n.genreRobots;
      case 'mystery':
        return l10n.genreMystery;
      case 'funny':
        return l10n.genreFunny;
      case 'educational':
        return l10n.genreEducational;
      case 'bedtime':
        return l10n.genreBedtime;
      default:
        return genre;
    }
  }
}