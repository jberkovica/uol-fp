import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/page_transitions.dart';
import 'signup_screen.dart';
import '../../generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  int _loginAttempts = 0;
  DateTime? _lastFailedAttempt;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    // Check rate limiting
    if (_isRateLimited()) {
      _setError('Too many failed attempts. Please wait before trying again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Reset failed attempts on success
        _loginAttempts = 0;
        _lastFailedAttempt = null;
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/profile-select');
        }
      } else {
        _handleLoginFailure('Invalid email or password. Please check your credentials.');
      }
    } catch (e) {
      _handleLoginFailure(_getErrorMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    final localizations = AppLocalizations.of(context)!;
    
    try {
      final response = await AuthService.instance.signInWithGoogle();
      if (kIsWeb) {
        // On web, OAuth happens via redirect, so we don't need to handle navigation here
        return;
      }
      
      if (response?.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-select');
      } else {
        _showError(localizations.googleSignInFailed);
      }
    } catch (e) {
      _showError('${localizations.googleSignInFailed}: ${e.toString()}');
    } finally {
      if (!kIsWeb) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    
    final localizations = AppLocalizations.of(context)!;
    
    try {
      final response = await AuthService.instance.signInWithApple();
      if (kIsWeb) {
        // On web, OAuth happens via redirect, so we don't need to handle navigation here
        return;
      }
      
      if (response?.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-select');
      } else {
        _showError(localizations.appleSignInFailed);
      }
    } catch (e) {
      _showError('${localizations.appleSignInFailed}: ${e.toString()}');
    } finally {
      if (!kIsWeb) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    
    final localizations = AppLocalizations.of(context)!;
    
    try {
      final response = await AuthService.instance.signInWithFacebook();
      if (kIsWeb) {
        // On web, OAuth happens via redirect, so we don't need to handle navigation here
        return;
      }
      
      if (response?.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-select');
      } else {
        _showError(localizations.facebookSignInFailed);
      }
    } catch (e) {
      _showError('${localizations.facebookSignInFailed}: ${e.toString()}');
    } finally {
      if (!kIsWeb) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLoginFailure(String message) {
    _loginAttempts++;
    _lastFailedAttempt = DateTime.now();
    _setError(message);
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  bool _isRateLimited() {
    if (_loginAttempts >= 3 && _lastFailedAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastFailedAttempt!);
      return timeSinceLastAttempt.inMinutes < 5; // 5 minute lockout
    }
    return false;
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid_credentials') || errorString.contains('invalid login')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (errorString.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in.';
    } else if (errorString.contains('too_many_requests')) {
      return 'Too many login attempts. Please try again later.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildSocialImageButton({
    required VoidCallback? onPressed,
    required String imagePath,
    bool isSvg = false,
  }) {
    return SizedBox(
      width: 64,
      height: 64,
      child: IconButton(
        onPressed: onPressed,
        icon: SizedBox(
          width: 32,
          height: 32,
          child: isSvg
              ? SvgPicture.asset(
                  imagePath,
                  width: 32,
                  height: 32,
                  colorFilter: onPressed == null 
                      ? ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn)
                      : null,
                )
              : Image.asset(
                  imagePath,
                  width: 32,
                  height: 32,
                  color: onPressed == null ? Colors.grey[400] : null,
                  colorBlendMode: onPressed == null ? BlendMode.saturation : null,
                ),
        ),
        splashRadius: 32,
        padding: EdgeInsets.zero,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: screenSize.width > 600 ? 400 : double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Logo section
                const SizedBox(height: 40),
                SvgPicture.asset(
                  'assets/images/mira-logo.svg',
                  width: 120,
                  height: 48,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textLight,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 48),

                // Login Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error message display
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.email,
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.pleaseEnterEmail;
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.password,
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.pleaseEnterPassword;
                            }
                            if (value.length < 6) {
                              return AppLocalizations.of(context)!.passwordMinLength;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmail,
                            style: AppTheme.authButtonStyle,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(AppLocalizations.of(context)!.signIn),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Social sign in buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Google sign in
                            _buildSocialImageButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              imagePath: 'assets/images/auth/google.png',
                            ),
                            
                            // Apple sign in
                            _buildSocialImageButton(
                              onPressed: _isLoading ? null : _signInWithApple,
                              imagePath: 'assets/images/auth/apple.svg',
                              isSvg: true,
                            ),
                            
                            // Facebook sign in
                            _buildSocialImageButton(
                              onPressed: _isLoading ? null : _signInWithFacebook,
                              imagePath: 'assets/images/auth/facebook.png',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.dontHaveAccount,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          NoAnimationRoute(page: const SignupScreen()),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.signUp,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}