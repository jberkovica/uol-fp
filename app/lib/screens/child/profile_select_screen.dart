import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
    final appearanceController = TextEditingController();
    final notesController = TextEditingController();
    
    String selectedAvatarType = 'profile1';
    int selectedAge = 5; // Age is now mandatory
    String? appearanceMethod;
    List<String> selectedGenres = [];
    String preferredLanguage = 'en';
    
    bool isExtractingAppearance = false;
    File? selectedImage;

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
                AppLocalizations.of(context)!.addNewProfile,
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
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset(
                                'assets/icons/user-filled.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(AppColors.textGrey, BlendMode.srcIn),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Age Selection (now mandatory)
                      Text(
                        'Age (Required)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(10, (index) {
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
                      ),
                      const SizedBox(height: 20),
                      
                      // Avatar Selection
                      Text(
                        '${AppLocalizations.of(context)!.chooseAvatar}:',
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
                      
                      // Appearance Section
                      Text(
                        'Appearance (Optional)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Describe how your child looks to help create personalized stories.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Appearance method selector
                      _buildDialogAppearanceMethodSelector(
                        appearanceMethod: appearanceMethod,
                        isExtractingAppearance: isExtractingAppearance,
                        onMethodSelected: (method) async {
                          if (method == 'photo') {
                            // Handle photo upload
                            await _pickAndExtractFromPhotoDialog(
                              nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'your child',
                              selectedAge,
                              setDialogState,
                              (description) {
                                setDialogState(() {
                                  appearanceController.text = description;
                                  appearanceMethod = 'photo';
                                  isExtractingAppearance = false;
                                });
                              },
                            );
                          } else {
                            setDialogState(() {
                              appearanceMethod = method == appearanceMethod ? null : method;
                            });
                          }
                        },
                        onExtractionStart: () {
                          setDialogState(() {
                            isExtractingAppearance = true;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Appearance description field
                      _buildDialogAppearanceDescriptionField(
                        controller: appearanceController,
                        appearanceMethod: appearanceMethod,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Favorite Genres Selection
                      Text(
                        'Favorite Story Types (Optional)',
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
                      const SizedBox(height: 20),
                      
                      // Parent Notes
                      Text(
                        'Parent Notes (Optional)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Special context for stories: hobbies, pets, siblings, interests, etc.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGrey, width: 1),
                        ),
                        child: TextField(
                          controller: notesController,
                          maxLines: 3,
                          maxLength: 300,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Example: Loves dinosaurs, has a pet cat named Whiskers...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textGrey,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
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
                    AppLocalizations.of(context)!.cancel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                ElevatedButton(
                  onPressed: isExtractingAppearance ? null : () async {
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
                        appearanceMethod: appearanceMethod,
                        appearanceDescription: appearanceController.text.trim().isEmpty 
                            ? null 
                            : appearanceController.text.trim(),
                        favoriteGenres: selectedGenres,
                        parentNotes: notesController.text.trim().isEmpty 
                            ? null 
                            : notesController.text.trim(),
                        preferredLanguage: preferredLanguage,
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
                  child: isExtractingAppearance 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.createProfile,
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

  // Photo upload and extraction for create dialog
  Future<void> _pickAndExtractFromPhotoDialog(
    String kidName,
    int age,
    Function(VoidCallback) setDialogState,
    Function(String) onDescriptionExtracted,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Convert image to base64 for API call
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call appearance extraction API
      final extractedDescription = await _extractAppearanceFromImage(
        base64Image,
        kidName,
        age,
      );

      if (extractedDescription != null) {
        onDescriptionExtracted(extractedDescription);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appearance extracted! You can review and edit the description below.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to extract appearance: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
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

  Widget _buildDialogAppearanceMethodSelector({
    required String? appearanceMethod,
    required bool isExtractingAppearance,
    required Function(String) onMethodSelected,
    required VoidCallback onExtractionStart,
  }) {
    final methods = [
      {'key': 'manual', 'label': 'Describe in words', 'icon': 'assets/icons/pencil-plus.svg'},
      {'key': 'photo', 'label': 'Upload photo', 'icon': 'assets/icons/camera-filled.svg'},
    ];
    
    return Column(
      children: methods.map((method) {
        final isSelected = appearanceMethod == method['key'];
        final isPhoto = method['key'] == 'photo';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () async {
              if (isPhoto) {
                onExtractionStart();
                await onMethodSelected(method['key'] as String);
              } else {
                await onMethodSelected(method['key'] as String);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.lightGrey,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  if (isExtractingAppearance && isPhoto)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  else
                    SvgPicture.asset(
                      method['icon'] as String,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isSelected ? AppColors.primary : AppColors.textDark,
                        BlendMode.srcIn,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExtractingAppearance && isPhoto 
                              ? 'Extracting appearance...' 
                              : method['label'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (isPhoto && !isExtractingAppearance)
                          Text(
                            'AI will analyze the photo and create a description',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected && !isExtractingAppearance)
                    SvgPicture.asset(
                      'assets/icons/circle-check-filled.svg',
                      width: 16,
                      height: 16,
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

  Widget _buildDialogAppearanceDescriptionField({
    required TextEditingController controller,
    required String? appearanceMethod,
  }) {
    final isFromPhoto = appearanceMethod == 'photo' && controller.text.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFromPhoto) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/circle-check-filled.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI extracted this description. Feel free to review and edit it.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey, width: 1),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: appearanceMethod == 'photo' 
                  ? 'Upload a photo above to auto-generate description, or type manually'
                  : 'Example: "Curly brown hair, bright green eyes, and a gap-toothed smile"',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGrey,
              ),
              helperText: isFromPhoto 
                  ? 'You can edit this AI-generated description.'
                  : 'Describe hair, eyes, distinctive features, etc.',
              helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textGrey,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
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
              child: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
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
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/plus.svg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.addKid,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

}
