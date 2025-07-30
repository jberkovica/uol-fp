import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  
  double _scrollOffset = 0.0;
  int? _selectedAge;
  String _selectedAvatarType = 'profile1';
  String? _selectedHairColor;
  String? _selectedHairLength;
  String? _selectedSkinColor;
  String? _selectedEyeColor;
  String? _selectedGender;
  List<String> _selectedGenres = [];
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.kid.name);
    _notesController = TextEditingController(text: ''); // TODO: Add notes field to backend
    
    _selectedAge = widget.kid.age;
    _selectedAvatarType = widget.kid.avatarType;
    _selectedHairColor = widget.kid.hairColor;
    _selectedHairLength = widget.kid.hairLength;
    _selectedSkinColor = widget.kid.skinColor;
    _selectedEyeColor = widget.kid.eyeColor;
    _selectedGender = widget.kid.gender;
    _selectedGenres = List.from(widget.kid.favoriteGenres);
    
    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
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

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
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
        hairColor: _selectedHairColor,
        hairLength: _selectedHairLength,
        skinColor: _selectedSkinColor,
        eyeColor: _selectedEyeColor,
        gender: _selectedGender,
        favoriteGenres: _selectedGenres,
      );

      // Update backend
      await KidService.updateKid(
        kidId: widget.kid.id,
        name: _nameController.text.trim(),
        age: _selectedAge,
        avatarType: _selectedAvatarType,
        hairColor: _selectedHairColor,
        hairLength: _selectedHairLength,
        skinColor: _selectedSkinColor,
        eyeColor: _selectedEyeColor,
        gender: _selectedGender,
        favoriteGenres: _selectedGenres,
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
          AppLocalizations.of(context)!.ageOptional,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildAgeSelector(),
        
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
          AppLocalizations.of(context)!.appearanceOptional,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        
        Text(
          AppLocalizations.of(context)!.hairColor,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildColorSelector(
          colors: KidProfileConstants.hairColors,
          selectedColor: _selectedHairColor,
          onColorSelected: (color) {
            setState(() {
              _selectedHairColor = color;
            });
            _onSelectionChanged();
          },
        ),
        
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.hairLength,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildHairLengthSelector(),
        
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.skinColor,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildColorSelector(
          colors: KidProfileConstants.skinColors,
          selectedColor: _selectedSkinColor,
          onColorSelected: (color) {
            setState(() {
              _selectedSkinColor = color;
            });
            _onSelectionChanged();
          },
        ),
        
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.eyeColor,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildColorSelector(
          colors: KidProfileConstants.eyeColors,
          selectedColor: _selectedEyeColor,
          onColorSelected: (color) {
            setState(() {
              _selectedEyeColor = color;
            });
            _onSelectionChanged();
          },
        ),
      ],
    );
  }

  Widget _buildPersonalitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.personalityPreferencesOptional,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        
        Text(
          AppLocalizations.of(context)!.gender,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildGenderSelector(),
        
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.favoriteStoryTypes,
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
          AppLocalizations.of(context)!.additionalNotesOptional,
          style: Theme.of(context).textTheme.headlineMedium,
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

  Widget _buildColorSelector({
    required Map<String, Color> colors,
    required String? selectedColor,
    required Function(String?) onColorSelected,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // None option
        GestureDetector(
          onTap: () => onColorSelected(null),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedColor == null ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: selectedColor == null
                ? SvgPicture.asset(
                    'assets/icons/copy-check.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                  )
                : SvgPicture.asset(
                    'assets/icons/x.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.grey, BlendMode.srcIn),
                  ),
          ),
        ),
        // Color options
        ...colors.entries.map((entry) {
          final colorKey = entry.key;
          final color = entry.value;
          final isSelected = selectedColor == colorKey;
          
          return GestureDetector(
            onTap: () => onColorSelected(colorKey),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? SvgPicture.asset(
                      'assets/icons/copy-check.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(_getContrastColor(color), BlendMode.srcIn),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHairLengthSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KidProfileConstants.hairLengths.map((length) {
        final isSelected = _selectedHairLength == length;
        final displayName = KidProfileConstants.getHairLengthDisplayName(length);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedHairLength = isSelected ? null : length;
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
              displayName,
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

  Widget _buildGenderSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KidProfileConstants.genderOptions.map((gender) {
        final isSelected = _selectedGender == gender;
        final displayName = KidProfileConstants.getGenderDisplayName(gender);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGender = isSelected ? null : gender;
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
              displayName,
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
        final displayName = KidProfileConstants.getGenreDisplayName(genre);
        
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

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}