import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/profile_avatar.dart';
import '../../generated/app_localizations.dart';

class AvatarSelectorSheet extends StatefulWidget {
  final String currentAvatarType;
  final ValueChanged<String> onAvatarSelected;

  const AvatarSelectorSheet({
    super.key,
    required this.currentAvatarType,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarSelectorSheet> createState() => _AvatarSelectorSheetState();
}

class _AvatarSelectorSheetState extends State<AvatarSelectorSheet> {
  late String _selectedAvatarType;

  @override
  void initState() {
    super.initState();
    _selectedAvatarType = widget.currentAvatarType;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                l10n.chooseAnAvatar,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              
              // Avatar grid
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
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAvatarSelected(_selectedAvatarType);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.saveChanges,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Show the avatar selector as a bottom sheet
  static Future<String?> show(
    BuildContext context, {
    required String currentAvatarType,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarSelectorSheet(
        currentAvatarType: currentAvatarType,
        onAvatarSelected: (avatarType) {
          Navigator.of(context).pop(avatarType);
        },
      ),
    );
  }
}