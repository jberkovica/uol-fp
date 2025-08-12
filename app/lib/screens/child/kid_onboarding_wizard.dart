import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';
import '../../constants/kid_profile_constants.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/age_input_field.dart';
import '../../services/auth_service.dart';
import '../../services/kid_service.dart';
import '../../generated/app_localizations.dart';

class KidOnboardingWizard extends StatefulWidget {
  const KidOnboardingWizard({super.key});

  @override
  State<KidOnboardingWizard> createState() => _KidOnboardingWizardState();
}

class _KidOnboardingWizardState extends State<KidOnboardingWizard> {
  int _currentStep = 0;
  final int _totalSteps = 7;
  bool _isCreating = false;
  
  // Centralized localization getter for better performance and cleaner code
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      throw Exception('AppLocalizations not found. Make sure the app is properly configured with localization delegates.');
    }
    return localizations;
  }
  
  // Form data
  final _nameController = TextEditingController();
  String _selectedAvatarType = 'profile1';
  int _selectedAge = 5;
  String? _selectedGender;
  String? _appearanceMethod;
  final _appearanceController = TextEditingController();
  final List<String> _selectedGenres = [];
  final _notesController = TextEditingController();
  bool _isExtractingAppearance = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _appearanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_canProceed()) {
      setState(() {
        if (_currentStep < _totalSteps - 1) {
          _currentStep++;
        }
      });
    }
  }
  
  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Name & Avatar
        return _nameController.text.trim().isNotEmpty;
      case 1: // Age
        return true; // Age always has a default value
      case 2: // Gender
        return _selectedGender != null;
      case 3: // Appearance (optional)
      case 4: // Genres (optional)
      case 5: // Notes (optional)
        return true; // Optional steps can always proceed
      case 6: // Review
        return !_isCreating;
      default:
        return false;
    }
  }
  
  bool _hasOptionalData() {
    // Check if optional steps have data entered
    switch (_currentStep) {
      case 3: // Appearance step
        return _appearanceController.text.trim().isNotEmpty;
      case 4: // Genres step
        return _selectedGenres.isNotEmpty;
      case 5: // Notes step
        return _notesController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }
  
  bool _isOptionalStep() {
    return _currentStep == 3 || _currentStep == 4 || _currentStep == 5;
  }
  
  String _getMainButtonText() {
    if (_currentStep == _totalSteps - 1) {
      return l10n.createProfile;
    }
    if (_isOptionalStep() && !_hasOptionalData()) {
      return l10n.skip;
    }
    return l10n.continueButton;
  }
  
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return l10n.wizardNameTitle;
      case 1:
        return l10n.wizardAgeTitle;
      case 2:
        return l10n.wizardGenderTitle;
      case 3:
        return l10n.wizardAppearanceTitle;
      case 4:
        return l10n.wizardGenresTitle;
      case 5:
        return l10n.wizardNotesTitle;
      case 6:
        return l10n.wizardReviewTitle;
      default:
        return "";
    }
  }
  
  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return l10n.wizardNameSubtitle;
      case 1:
        return l10n.wizardAgeSubtitle;
      case 2:
        return l10n.wizardGenderSubtitle;
      case 3:
        return l10n.wizardAppearanceSubtitle;
      case 4:
        return l10n.wizardGenresSubtitle;
      case 5:
        return l10n.wizardNotesSubtitle;
      case 6:
        return l10n.wizardReviewSubtitle;
      default:
        return "";
    }
  }
  
  Widget _getStepIcon() {
    switch (_currentStep) {
      case 0:
        return SvgPicture.asset('assets/icons/mood-smile-filled.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn));
      case 1:
        return SvgPicture.asset('assets/icons/star-filled.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.orange, BlendMode.srcIn));
      case 2:
        return SvgPicture.asset('assets/icons/heart-filled.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn));
      case 3:
        return SvgPicture.asset('assets/icons/camera-filled.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn));
      case 4:
        return SvgPicture.asset('assets/icons/star-filled.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.orange, BlendMode.srcIn));
      case 5:
        return SvgPicture.asset('assets/icons/message-heart.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn));
      case 6:
        return SvgPicture.asset('assets/icons/star-filled.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn));
      default:
        return SvgPicture.asset('assets/icons/circle-plus-filled.svg', width: 48, height: 48, colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn));
    }
  }
  
  Color _getStepBackgroundColor() {
    // Each step gets its own beautiful pastel background - neutral and welcoming
    switch (_currentStep) {
      case 0: // Name & Avatar
        return AppColors.violetSoft; // Very light violet - welcoming
      case 1: // Age
        return AppColors.secondary.withValues(alpha: 0.4); // Soft yellow - cheerful
      case 2: // Gender
        return AppColors.violetLight.withValues(alpha: 0.2); // Very light violet - neutral
      case 3: // Appearance
        return AppColors.orangeLight.withValues(alpha: 0.5); // Soft orange - creative
      case 4: // Genres
        return AppColors.secondary.withValues(alpha: 0.3); // Light yellow - magical
      case 5: // Notes
        return AppColors.violetLight.withValues(alpha: 0.25); // Soft violet - thoughtful
      case 6: // Review
        return AppColors.secondary.withValues(alpha: 0.35); // Warm yellow - completion
      default:
        return AppColors.violetSoft;
    }
  }
  
  Future<void> _createKid() async {
    setState(() {
      _isCreating = true;
    });
    
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final newKid = await KidService.createKid(
        userId: user.id,
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
        preferredLanguage: 'en', // TODO: Get from language settings
      );
      
      if (mounted) {
        Navigator.of(context).pop(newKid);
      }
    } catch (e) {
      // Log the detailed error for debugging
      debugPrint('Error creating kid profile: ${e.toString()}');
      
      if (mounted) {
        String userMessage;
        
        // Provide user-friendly error messages based on error type
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          userMessage = 'Please check your internet connection and try again.';
        } else if (e.toString().contains('authentication') || e.toString().contains('User not authenticated')) {
          userMessage = 'Please sign in again to create a profile.';
        } else if (e.toString().contains('validation')) {
          userMessage = 'Please check that all required fields are filled correctly.';
        } else {
          userMessage = AppLocalizations.of(context)?.failedToCreateProfile('Please try again.') ?? 'Failed to create profile. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.white,
              onPressed: () => _createKid(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getStepBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: SvgPicture.asset('assets/icons/arrow-left.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(AppColors.textDark, BlendMode.srcIn)),
                      onPressed: _previousStep,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  IconButton(
                    icon: SvgPicture.asset('assets/icons/x.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(AppColors.textDark, BlendMode.srcIn)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      _getStepIcon(),
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        _getStepTitle(),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        _getStepSubtitle(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Step Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildStepContent(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Navigation Buttons
                      _buildNavigationButtons(),
                      
                      const SizedBox(height: 24),
                      
                      // Progress Indicator
                      _buildProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameAndAvatarStep();
      case 1:
        return _buildAgeStep();
      case 2:
        return _buildGenderStep();
      case 3:
        return _buildAppearanceStep();
      case 4:
        return _buildGenresStep();
      case 5:
        return _buildNotesStep();
      case 6:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildNameAndAvatarStep() {
    return Column(
      children: [
        // Name Input
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey, width: 2),
          ),
          child: TextField(
            controller: _nameController,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.enterName ?? "Enter name",
              hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textGrey,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 32),
        
        // Avatar Selection
        Text(
          l10n.chooseAnAvatar,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: ProfileType.values.map((type) {
            final typeString = ProfileAvatar.typeToString(type);
            final isSelected = _selectedAvatarType == typeString;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatarType = typeString;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: ProfileAvatar(
                  radius: 40,
                  profileType: type,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildAgeStep() {
    return Column(
      children: [
        // Age display circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.orange, width: 3),
          ),
          child: Center(
            child: Text(
              _selectedAge.toString(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Clean age input field
        AgeInputField(
          initialAge: _selectedAge,
          onAgeChanged: (age) {
            setState(() {
              _selectedAge = age;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildGenderStep() {
    final options = [
      {'value': 'boy', 'label': l10n.boy, 'icon': 'assets/icons/user-filled.svg'},
      {'value': 'girl', 'label': l10n.girl, 'icon': 'assets/icons/user-filled.svg'},
      {'value': 'other', 'label': l10n.preferNotToSay, 'icon': 'assets/icons/user-filled.svg'},
    ];
    
    return Column(
      children: options.map((option) {
        final isSelected = _selectedGender == option['value'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedGender = option['value'] as String;
              });
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
                  SvgPicture.asset(
                    option['icon'] as String,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(isSelected ? AppColors.primary : AppColors.textGrey, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option['label'] as String,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    SvgPicture.asset(
                      'assets/icons/circle-check-filled.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildAppearanceStep() {
    return Column(
      children: [
        // Method selector
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _appearanceMethod = _appearanceMethod == 'manual' ? null : 'manual';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _appearanceMethod == 'manual' 
                        ? AppColors.primary.withValues(alpha: 0.1) 
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _appearanceMethod == 'manual' 
                          ? AppColors.primary 
                          : AppColors.lightGrey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/pencil-plus.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          _appearanceMethod == 'manual' 
                              ? AppColors.primary 
                              : AppColors.textGrey,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.describe,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    _appearanceMethod = 'photo';
                  });
                  await _pickAndExtractFromPhoto();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _appearanceMethod == 'photo' 
                        ? AppColors.primary.withValues(alpha: 0.1) 
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _appearanceMethod == 'photo' 
                          ? AppColors.primary 
                          : AppColors.lightGrey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _isExtractingAppearance
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/camera-filled.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                _appearanceMethod == 'photo' 
                                    ? AppColors.primary 
                                    : AppColors.textGrey,
                                BlendMode.srcIn,
                              ),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        _isExtractingAppearance ? l10n.analyzing : l10n.uploadPhoto,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (_appearanceMethod != null) ...[
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey, width: 1),
            ),
            child: TextField(
              controller: _appearanceController,
              maxLines: 4,
              maxLength: 500,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: _appearanceMethod == 'photo'
                    ? l10n.aiExtractedAppearanceWillAppearHere
                    : l10n.appearanceDescriptionPlaceholder,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: "",
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildGenresStep() {
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
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange.withValues(alpha: 0.2) : AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.orange : AppColors.lightGrey,
                width: 2,
              ),
            ),
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.orange : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildNotesStep() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey, width: 1),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 6,
        maxLength: 300,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: l10n.parentNotesHintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textGrey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterText: "",
        ),
      ),
    );
  }
  
  Widget _buildReviewStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile summary
          Row(
            children: [
              ProfileAvatar(
                radius: 40,
                profileType: ProfileAvatar.fromString(_selectedAvatarType),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.trim(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      "$_selectedAge ${AppLocalizations.of(context)?.yearsOld ?? 'years old'} • ${_selectedGender == 'boy' ? (AppLocalizations.of(context)?.boy ?? 'Boy') : _selectedGender == 'girl' ? (AppLocalizations.of(context)?.girl ?? 'Girl') : (AppLocalizations.of(context)?.preferNotToSay ?? 'Prefer not to say')}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_appearanceController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              l10n.appearance,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _appearanceController.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
          
          if (_selectedGenres.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              l10n.favoriteStoryTypes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedGenres.map((genre) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getLocalizedGenreName(genre),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
            ),
          ],
          
          if (_notesController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              l10n.specialNotes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _notesController.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.lightGrey, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/icons/arrow-left.svg', width: 20, height: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.back ?? "Back",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        
        
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _canProceed() 
                ? (_currentStep == _totalSteps - 1 ? _createKid : _nextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep == _totalSteps - 1 
                  ? AppColors.primary 
                  : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCreating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getMainButtonText(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        _currentStep == _totalSteps - 1 
                            ? 'assets/icons/check.svg' 
                            : (_isOptionalStep() && !_hasOptionalData())
                                ? 'assets/icons/arrow-right.svg' // Skip arrow
                                : 'assets/icons/arrow-right.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Text(
          l10n.stepOfSteps(_currentStep + 1, _totalSteps),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * ((_currentStep + 1) / _totalSteps),
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  Future<void> _pickAndExtractFromPhoto() async {
    setState(() {
      _isExtractingAppearance = true;
    });
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) {
        setState(() {
          _appearanceMethod = null;
          _isExtractingAppearance = false;
        });
        return;
      }
      
      // Convert image to base64 for API call
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Call appearance extraction API
      final extractedDescription = await _extractAppearanceFromImage(
        base64Image,
        _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'your child',
        _selectedAge,
      );
      
      if (extractedDescription != null) {
        setState(() {
          _appearanceController.text = extractedDescription;
          _isExtractingAppearance = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.appearanceExtractedSuccess ?? 'Appearance extracted! You can review and edit below.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _appearanceMethod = null;
        _isExtractingAppearance = false;
      });
      
      if (mounted) {
        debugPrint('Error extracting appearance from photo: ${e.toString()}');
        
        String userMessage;
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          userMessage = 'Please check your internet connection and try uploading again.';
        } else if (e.toString().contains('format') || e.toString().contains('image')) {
          userMessage = 'Please try with a different photo. Make sure it\'s a clear image.';
        } else {
          userMessage = AppLocalizations.of(context)?.failedToExtractAppearance('Please try again or describe manually.') ?? 'Failed to analyze photo. Please try again or describe manually.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
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
  
  String _getLocalizedGenreName(String genre) {
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