import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_theme.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  late Timer _timer;
  int _currentStep = 0;
  final List<String> _messages = [
    'Magic is happening...',
    'Creating your story...',
    'Almost ready...',
    'Your tale is ready!'
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        if (_currentStep < 3) {
          _currentStep++;
        } else {
          _timer.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/story-display');
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.yellowScreenBackground, // Yellow background for processing screen
      body: SafeArea(
        child: Center(
          // Center everything
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAnimatedMascot(),
              const SizedBox(height: 40),
              _buildMessage(),
              const SizedBox(height: 60),
              _currentStep == 3
                  ? _buildReadyButton(context)
                  : const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedMascot() {
    return Center(
      // Ensure centering
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: SvgPicture.asset(
          _currentStep >= 2 ? AppAssets.miraInClouds : AppAssets.miraWaiting,
          key: ValueKey<int>(_currentStep),
          width: 160, // Larger size
          height: 160,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          _messages[_currentStep],
          key: ValueKey<int>(_currentStep),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildReadyButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/story-display');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0, // NO shadow
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      child: Text(
        'Read',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
