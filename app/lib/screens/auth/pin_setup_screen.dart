import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';
import '../../generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../child/profile_select_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AuthService _authService = AuthService.instance;
  
  String _enteredPin = '';
  bool _isSettingPin = false;
  String? _errorMessage;

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _setupPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _setupPin() async {
    if (_enteredPin.length != 4) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseEnterAllFourDigits;
      });
      return;
    }

    setState(() {
      _isSettingPin = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.updateParentPin(_enteredPin);

      if (success) {
        // PIN setup successful, navigate to profile selection screen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSelectScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.failedToSetPin;
          _isSettingPin = false;
        });
        _clearPin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.failedToSetPin;
        _isSettingPin = false;
      });
      _clearPin();
    }
  }

  void _clearPin() {
    setState(() {
      _enteredPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
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
                          AppLocalizations.of(context)!.setYourParentPin,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textLight,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        
                        // PIN dots - clean white circles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            bool isFilled = index < _enteredPin.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _errorMessage != null 
                                    ? AppColors.error
                                    : (isFilled ? AppColors.white : AppColors.white.withValues(alpha: 0.3)),
                              ),
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Number pad - matching parent dashboard style
                        _buildNumberPad(),
                        
                        const SizedBox(height: 32),
                        
                        // Processing indicator
                        if (_isSettingPin)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.settingUpYourPin,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        
                        const SizedBox(height: 48),
                        
                        // Help text
                        Text(
                          AppLocalizations.of(context)!.thisWillBeUsedForAccess,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
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
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSettingPin ? null : () => _onNumberTap(number),
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
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSettingPin ? null : _onDeleteTap,
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: Icon(
              LucideIcons.delete,
              color: AppColors.textLight,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}