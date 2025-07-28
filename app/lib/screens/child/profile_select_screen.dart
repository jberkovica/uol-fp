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
    int selectedAge = 5; // Default age
    String? selectedHairColor;
    String? selectedSkinColor;
    String? selectedEyeColor;
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
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.enterChildName,
                          border: const OutlineInputBorder(),
                        ),
                        style: Theme.of(context).textTheme.headlineLarge,
                        autofocus: true,
                      ),
                      const SizedBox(height: 20),
                      
                      // Age Selection
                      Text(
                        'Age:',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(10, (index) {
                          final age = index + 3; // Ages 3-12
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedAge = age;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedAge == age 
                                    ? AppColors.primary 
                                    : AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedAge == age 
                                      ? AppColors.primary 
                                      : AppColors.grey,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  age.toString(),
                                  style: TextStyle(
                                    color: selectedAge == age 
                                        ? Colors.white 
                                        : AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      
                      // Avatar Selection
                      Text(
                        'Choose Avatar:',
                        style: Theme.of(context).textTheme.headlineLarge,
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
                        style: Theme.of(context).textTheme.headlineLarge,
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
                      
                      // Skin Color Selection
                      Text(
                        'Skin Color (Optional):',
                        style: Theme.of(context).textTheme.headlineLarge,
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
                        style: Theme.of(context).textTheme.headlineLarge,
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
                      
                      // Favorite Genres Selection
                      Text(
                        'Favorite Story Types (Optional):',
                        style: Theme.of(context).textTheme.headlineLarge,
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
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterName)),
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
                        skinColor: selectedSkinColor,
                        eyeColor: selectedEyeColor,
                        favoriteGenres: selectedGenres,
                      );
                      Navigator.of(context).pop(newKid);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateProfile(e.toString()))),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                  ),
                  child: Text(
                    'Add',
                    style: Theme.of(context).textTheme.headlineLarge,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedColor == null ? AppColors.primary : AppColors.grey,
                width: selectedColor == null ? 3 : 1,
              ),
            ),
            child: selectedColor == null
                ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                : const Icon(Icons.close, size: 12, color: AppColors.grey),
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.lightGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              displayName,
              style: TextStyle(
                color: isSelected ? AppColors.textDark : AppColors.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
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
