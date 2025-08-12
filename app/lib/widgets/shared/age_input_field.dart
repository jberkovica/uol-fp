import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../generated/app_localizations.dart';

class AgeInputField extends StatefulWidget {
  final int initialAge;
  final ValueChanged<int> onAgeChanged;
  final String? errorText;

  const AgeInputField({
    super.key,
    required this.initialAge,
    required this.onAgeChanged,
    this.errorText,
  });

  @override
  State<AgeInputField> createState() => _AgeInputFieldState();
}

class _AgeInputFieldState extends State<AgeInputField> {
  late TextEditingController _controller;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAge.toString());
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _validationError = AppLocalizations.of(context)?.pleaseEnterAge ?? 'Please enter age';
      });
      return;
    }

    final age = int.tryParse(text);
    if (age == null) {
      setState(() {
        _validationError = AppLocalizations.of(context)?.pleaseEnterValidAge ?? 'Please enter a valid age';
      });
      return;
    }

    if (age < 2 || age > 12) {
      setState(() {
        _validationError = AppLocalizations.of(context)?.ageRangeError ?? 'Age must be between 2 and 12';
      });
      return;
    }

    // Valid age
    setState(() {
      _validationError = null;
    });
    widget.onAgeChanged(age);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _validationError != null || widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.lightGrey,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.enterAge212 ?? 'Enter age (2-12)',
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textGrey,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Text(
            _validationError ?? widget.errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}