import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import '../../constants/app_colors.dart';
import '../../generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_auth_service.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _enteredPin = '';
  bool _isError = false;
  bool _biometricAvailable = false;
  BiometricType? _primaryBiometric;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    final biometricService = BiometricAuthService.instance;
    final isAvailable = await biometricService.isAvailable();
    
    if (isAvailable) {
      final primaryBiometric = await biometricService.getPrimaryBiometricType();
      setState(() {
        _biometricAvailable = true;
        _primaryBiometric = primaryBiometric;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (!_biometricAvailable || _isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    final biometricService = BiometricAuthService.instance;
    
    try {
      final authenticated = await biometricService.authenticate(
        reason: 'Please authenticate to access parent dashboard',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      if (authenticated && mounted) {
        Navigator.pushReplacementNamed(context, '/parent-dashboard-main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication failed. Please use PIN.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _validatePin();
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

  void _validatePin() {
    final correctPin = AuthService.instance.getParentPin();
    
    // If no PIN is set, redirect to PIN setup (shouldn't happen with existing users)
    if (correctPin == null) {
      Navigator.pushReplacementNamed(context, '/pin-setup');
      return;
    }
    
    if (_enteredPin == correctPin) {
      Navigator.pushReplacementNamed(context, '/parent-dashboard-main');
    } else {
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.incorrectPin),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
            // Top back button - positioned at top corner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
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
                          AppLocalizations.of(context)!.parentDashboard,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          AppLocalizations.of(context)!.enterPin,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textLight.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // PIN dots
                        _buildPinDots(),
                        
                        // Biometric button (if available)
                        if (_biometricAvailable)
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 16),
                            child: _buildBiometricButton(),
                          ),
                        
                        SizedBox(height: _biometricAvailable ? 24 : 40),

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
          child: const Center(
            child: Icon(
              LucideIcons.delete,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    // Get the appropriate icon for the biometric type
    IconData biometricIcon;
    String biometricText;
    
    switch (_primaryBiometric) {
      case BiometricType.face:
        biometricIcon = LucideIcons.scan;
        biometricText = 'Face ID';
        break;
      case BiometricType.fingerprint:
        biometricIcon = LucideIcons.fingerprint;
        biometricText = 'Fingerprint';
        break;
      default:
        biometricIcon = LucideIcons.shield;
        biometricText = 'Biometric';
    }

    return Column(
      children: [
        // Biometric icon button
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isAuthenticating ? null : _authenticateWithBiometric,
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: _isAuthenticating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        biometricIcon,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Biometric text
        Text(
          biometricText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}