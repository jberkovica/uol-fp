import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../generated/app_localizations.dart';
import '../../services/auth_service.dart';

enum PinStep { current, newPin, confirm }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  PinStep _currentStep = PinStep.current;
  String _enteredPin = '';
  String _newPin = '';
  bool _isError = false;

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _validateCurrentStep();
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  void _validateCurrentStep() {
    switch (_currentStep) {
      case PinStep.current:
        _validateCurrentPin();
        break;
      case PinStep.newPin:
        _saveNewPin();
        break;
      case PinStep.confirm:
        _confirmAndSavePin();
        break;
    }
  }

  void _validateCurrentPin() {
    final correctPin = AuthService.instance.getParentPin();
    
    if (_enteredPin == correctPin) {
      // Move to new PIN step
      setState(() {
        _currentStep = PinStep.newPin;
        _enteredPin = '';
      });
    } else {
      _showError(AppLocalizations.of(context)!.incorrectCurrentPin);
    }
  }

  void _saveNewPin() {
    _newPin = _enteredPin;
    setState(() {
      _currentStep = PinStep.confirm;
      _enteredPin = '';
    });
  }

  void _confirmAndSavePin() {
    if (_enteredPin == _newPin) {
      _updatePin();
    } else {
      _showError(AppLocalizations.of(context)!.pinsDoNotMatch);
    }
  }

  Future<void> _updatePin() async {
    final success = await AuthService.instance.updateParentPin(_newPin);
    
    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pinChangedSuccessfully),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      // Go back to parent dashboard
      Navigator.of(context).pop();
    } else if (mounted) {
      _showError('Failed to update PIN. Please try again.');
    }
  }

  void _showError(String message) {
    setState(() {
      _isError = true;
      _enteredPin = '';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case PinStep.current:
        return AppLocalizations.of(context)!.currentPin;
      case PinStep.newPin:
        return AppLocalizations.of(context)!.newPin;
      case PinStep.confirm:
        return AppLocalizations.of(context)!.confirmPin;
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Top back button and step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: SvgPicture.asset(
                          'assets/icons/arrow-left.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Minimalistic step indicator bar
                  _buildMinimalisticStepIndicator(),
                ],
              ),
            ),
            
            // Main content - centered and responsive
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: screenSize.width > 600 ? 400 : double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          _getStepTitle(),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // PIN dots
                        _buildPinDots(),
                        const SizedBox(height: 60),

                        // Number pad
                        _buildNumberPad(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalisticStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step 1
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        // Step 2
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: _currentStep.index >= PinStep.newPin.index 
                ? AppColors.white 
                : AppColors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        // Step 3
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: _currentStep.index >= PinStep.confirm.index 
                ? AppColors.white 
                : AppColors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < _enteredPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isError 
                ? AppColors.error
                : (isFilled ? Colors.white : Colors.white.withValues(alpha: 0.3)),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Row 4: empty, 0, delete
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80), // Empty space
            _buildNumberButton('0'),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNumberTap(number),
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textLight,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onDeleteTap,
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/x.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}