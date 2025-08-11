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
import 'kid_onboarding_wizard.dart';

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

  Future<void> _showCreateKidWizard() async {
    final result = await Navigator.push<Kid>(
      context,
      MaterialPageRoute(
        builder: (context) => const KidOnboardingWizard(),
        fullscreenDialog: true,
      ),
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
      {'key': 'manual', 'label': AppLocalizations.of(context)!.describeInWords, 'icon': 'assets/icons/pencil-plus.svg'},
      {'key': 'photo', 'label': AppLocalizations.of(context)!.uploadPhoto, 'icon': 'assets/icons/camera-filled.svg'},
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
                            AppLocalizations.of(context)!.aiWillAnalyzePhoto,
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
                  ? AppLocalizations.of(context)!.appearancePhotoPlaceholder
                  : AppLocalizations.of(context)!.appearanceExamplePlaceholder,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGrey,
              ),
              helperText: isFromPhoto 
                  ? AppLocalizations.of(context)!.aiGeneratedHelperText
                  : AppLocalizations.of(context)!.appearanceHelperText,
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
      onTap: _showCreateKidWizard,
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
        final displayName = _getLocalizedGenreName(context, genre);
        
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

  static String _getLocalizedGenreName(BuildContext context, String genre) {
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
