import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../generated/app_localizations.dart';

class GenderSelector extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final options = [
      {'value': 'boy', 'label': l10n.boy},
      {'value': 'girl', 'label': l10n.girl},
      {'value': 'other', 'label': l10n.preferNotToSay},
    ];

    return Row(
      children: options.map((option) {
        final value = option['value'] as String;
        final label = option['label'] as String;
        final isSelected = selectedGender == value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: value != 'other' ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onGenderChanged(value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}