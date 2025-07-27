import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/page_transitions.dart';
import 'login_screen.dart';
import '../../generated/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim().isEmpty 
            ? null 
            : _nameController.text.trim(),
      );

      if (response.user != null) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.accountCreatedSuccessfully),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Navigate to login screen
          Navigator.pushReplacement(
          context,
          NoAnimationRoute(page: const LoginScreen()),
        );
        }
      } else {
        _showError('Sign up failed. Please try again.');
      }
    } catch (e) {
      _showError('Sign up failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await AuthService.instance.signInWithGoogle();
      if (kIsWeb) {
        // On web, OAuth happens via redirect, so we don't need to handle navigation here
        return;
      }
      
      if (response?.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-select');
      } else {
        _showError(AppLocalizations.of(context)!.googleSignInFailed);
      }
    } catch (e) {
      _showError('${AppLocalizations.of(context)!.googleSignInFailed}: ${e.toString()}');
    } finally {
      if (!kIsWeb) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await AuthService.instance.signInWithApple();
      if (kIsWeb) {
        // On web, OAuth happens via redirect, so we don't need to handle navigation here
        return;
      }
      
      if (response?.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-select');
      } else {
        _showError(AppLocalizations.of(context)!.appleSignInFailed);
      }
    } catch (e) {
      _showError('${AppLocalizations.of(context)!.appleSignInFailed}: ${e.toString()}');
    } finally {
      if (!kIsWeb) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await AuthService.instance.signInWithFacebook();
      if (kIsWeb) {
        // On web, OAuth happens via redirect, so we don't need to handle navigation here
        return;
      }
      
      if (response?.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-select');
      } else {
        _showError(AppLocalizations.of(context)!.facebookSignInFailed);
      }
    } catch (e) {
      _showError('${AppLocalizations.of(context)!.facebookSignInFailed}: ${e.toString()}');
    } finally {
      if (!kIsWeb) {
        setState(() => _isLoading = false);
      }
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

                // Signup Form
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
                        // Name field (optional)
                        TextFormField(
                          controller: _nameController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.fullNameOptional,
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 16),

                        // Confirm Password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.confirmPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.pleaseConfirmPassword;
                            }
                            if (value != _passwordController.text) {
                              return AppLocalizations.of(context)!.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Sign up button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUpWithEmail,
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
                                : Text(AppLocalizations.of(context)!.createAccount),
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
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 24),

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

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.alreadyHaveAccount,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
          context,
          NoAnimationRoute(page: const LoginScreen()),
        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.signIn,
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