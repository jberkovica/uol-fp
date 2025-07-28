import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../constants/kid_profile_constants.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../services/auth_service.dart';
import '../../services/kid_service.dart';
import '../../services/app_state_service.dart';
import '../../models/kid.dart';
import '../../generated/app_localizations.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  List<Kid> _kids = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKids();
  }

  Future<void> _loadKids() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final kids = await KidService.getKidsForUser(user.id);
      setState(() {
        _kids = kids;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profiles: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateKidDialog() async {
    final nameController = TextEditingController();
    String selectedAvatarType = 'profile1';
    int? selectedAge = 5; // Default age, but optional
    String? selectedHairColor;
    String? selectedHairLength;
    String? selectedSkinColor;
    String? selectedEyeColor;
    String? selectedGender;
    List<String> selectedGenres = [];

    final result = await showDialog<Kid>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add New Profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGrey, width: 1),
                        ),
                        child: TextField(
                          controller: nameController,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterChildName,
                            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textGrey,
                            ),
                            prefixIcon: Icon(LucideIcons.user, color: AppColors.textGrey, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Age Selection
                      Text(
                        'Age (Optional):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // None option
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedAge = null;
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selectedAge == null ? AppColors.primary : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedAge == null ? AppColors.primary : AppColors.lightGrey,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: selectedAge == null
                                    ? Icon(LucideIcons.check, size: 20, color: Colors.white)
                                    : Icon(LucideIcons.x, size: 16, color: AppColors.grey),
                              ),
                            ),
                          ),
                          // Age options
                          ...List.generate(10, (index) {
                            final age = index + 3;
                            final isSelected = selectedAge == age;
                            
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedAge = age;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
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
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Avatar Selection
                      Text(
                        'Choose Avatar:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ProfileType.values.map((type) {
                          final typeString = ProfileAvatar.typeToString(type);
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedAvatarType = typeString;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: selectedAvatarType == typeString
                                    ? Border.all(color: AppColors.primary, width: 3)
                                    : null,
                              ),
                              child: ProfileAvatar(
                                radius: 28,
                                profileType: type,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      
                      // Hair Color Selection
                      Text(
                        'Hair Color (Optional):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildColorSelector(
                        colors: KidProfileConstants.hairColors,
                        selectedColor: selectedHairColor,
                        onColorSelected: (color) {
                          setDialogState(() {
                            selectedHairColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Hair Length Selection
                      Text(
                        'Hair Length (Optional):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHairLengthSelector(
                        selectedLength: selectedHairLength,
                        onLengthSelected: (length) {
                          setDialogState(() {
                            selectedHairLength = length;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Skin Color Selection
                      Text(
                        'Skin Color (Optional):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildColorSelector(
                        colors: KidProfileConstants.skinColors,
                        selectedColor: selectedSkinColor,
                        onColorSelected: (color) {
                          setDialogState(() {
                            selectedSkinColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Eye Color Selection
                      Text(
                        'Eye Color (Optional):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildColorSelector(
                        colors: KidProfileConstants.eyeColors,
                        selectedColor: selectedEyeColor,
                        onColorSelected: (color) {
                          setDialogState(() {
                            selectedEyeColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Gender Selection
                      Text(
                        'Gender (Optional):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGenderSelector(
                        selectedGender: selectedGender,
                        onGenderSelected: (gender) {
                          setDialogState(() {
                            selectedGender = gender;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Favorite Genres Selection
                      Text(
                        'Favorite Story Types (Optional):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGenreSelector(
                        selectedGenres: selectedGenres,
                        onGenresChanged: (genres) {
                          setDialogState(() {
                            selectedGenres = genres;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppTheme.cancelButtonStyle,
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.pleaseEnterName),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    try {
                      final user = AuthService.instance.currentUser;
                      if (user == null) throw Exception('User not authenticated');

                      final newKid = await KidService.createKid(
                        userId: user.id,
                        name: nameController.text.trim(),
                        age: selectedAge,
                        avatarType: selectedAvatarType,
                        hairColor: selectedHairColor,
                        hairLength: selectedHairLength,
                        skinColor: selectedSkinColor,
                        eyeColor: selectedEyeColor,
                        gender: selectedGender,
                        favoriteGenres: selectedGenres,
                      );
                      Navigator.of(context).pop(newKid);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create profile: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  style: AppTheme.modalActionButtonStyle,
                  child: Text(
                    'Create Profile',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _kids.add(result);
      });
    }
  }

  ProfileType _getProfileType(String avatarType) {
    return ProfileAvatar.fromString(avatarType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Column(
        children: [
          // Consistent header using AppTheme
          AppTheme.screenHeader(
            context: context,
            title: AppLocalizations.of(context)!.selectProfile,
            action: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/parent-dashboard');
              },
              child: const Icon(
                LucideIcons.settings,
                color: AppColors.textDark,
                size: 24,
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadKids,
                              child: Text(
                                'Retry',
                                style: Theme.of(context).textTheme.headlineLarge,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildModernProfileLayout(),
          ),
        ],
      ),
    );
  }



  Widget _buildModernProfileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        if (screenWidth < 768) {
          // Mobile/Small tablet: Single column
          return _buildSingleColumnLayout();
        } else {
          // Large tablet/Desktop: Two columns
          return _buildTwoColumnLayout();
        }
      },
    );
  }

  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: ResponsiveBreakpoints.getResponsiveAllPadding(context),
      child: Column(
        children: [
          ..._kids.map((kid) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSimpleProfileCard(
              name: kid.name,
              profileType: _getProfileType(kid.avatarType),
              onTap: () {
                // Save selected kid to local storage
                AppStateService.saveSelectedKid(kid);
                Navigator.pushNamed(
                  context,
                  '/child-home',
                  arguments: kid,
                );
              },
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAddProfileCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    final allItems = <Widget>[
      ..._kids.map((kid) => _buildSimpleProfileCard(
        name: kid.name,
        profileType: _getProfileType(kid.avatarType),
        onTap: () {
          // Save selected kid to local storage
          AppStateService.saveSelectedKid(kid);
          Navigator.pushNamed(
            context,
            '/child-home',
            arguments: kid,
          );
        },
      )),
      _buildAddProfileCard(),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), // Limit max width to group profiles
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          mainAxisSpacing: 8, // Further reduced vertical spacing
          crossAxisSpacing: 16, // Keep horizontal spacing
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          children: allItems,
        ),
      ),
    );
  }

  Widget _buildSimpleProfileCard({
    required String name,
    required ProfileType profileType,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileAvatar(
              radius: 60, // Increased from 50 to 60
              profileType: profileType,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileCard() {
    return GestureDetector(
      onTap: _showCreateKidDialog,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.3), // Light orange like in your design
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.plus,
                size: 32,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add profile',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    required Map<String, Color> colors,
    required String? selectedColor,
    required Function(String?) onColorSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "None" option
        GestureDetector(
          onTap: () => onColorSelected(null),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedColor == null ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: selectedColor == null
                ? Icon(LucideIcons.check, size: 20, color: AppColors.primary)
                : Icon(LucideIcons.x, size: 16, color: AppColors.grey),
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
              width: 48,
              height: 48,
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
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      LucideIcons.check,
                      size: 20,
                      color: _getContrastColor(color),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGenreSelector({
    required List<String> selectedGenres,
    required Function(List<String>) onGenresChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KidProfileConstants.storyGenres.map((genre) {
        final isSelected = selectedGenres.contains(genre);
        final displayName = KidProfileConstants.getGenreDisplayName(genre);
        
        return GestureDetector(
          onTap: () {
            final newGenres = List<String>.from(selectedGenres);
            if (isSelected) {
              newGenres.remove(genre);
            } else {
              newGenres.add(genre);
            }
            onGenresChanged(newGenres);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.white,
              borderRadius: BorderRadius.circular(20),
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

  Widget _buildHairLengthSelector({
    required String? selectedLength,
    required Function(String?) onLengthSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KidProfileConstants.hairLengths.map((length) {
        final isSelected = selectedLength == length;
        final displayName = KidProfileConstants.getHairLengthDisplayName(length);
        
        return GestureDetector(
          onTap: () {
            onLengthSelected(isSelected ? null : length);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(20),
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

  Widget _buildGenderSelector({
    required String? selectedGender,
    required Function(String?) onGenderSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KidProfileConstants.genderOptions.map((gender) {
        final isSelected = selectedGender == gender;
        final displayName = KidProfileConstants.getGenderDisplayName(gender);
        
        return GestureDetector(
          onTap: () {
            onGenderSelected(isSelected ? null : gender);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(20),
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

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we need dark or light text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
