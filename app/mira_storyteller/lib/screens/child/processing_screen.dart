import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../widgets/character_avatar.dart';

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
    // Simulate processing steps with a timer
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        if (_currentStep < 3) {
          _currentStep++;
        } else {
          _timer.cancel();
          // Navigate to story screen after a short delay
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildAnimatedCharacters(),
              const SizedBox(height: 60),
              _buildMessage(),
              const SizedBox(height: 80),
              _currentStep == 3 ? _buildReadyButton(context) : const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCharacters() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Character
        AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: const CharacterAvatar(
            radius: 60,
            characterType: CharacterType.hero2,
          ),
        ),
        
        // Clouds - only visible in later steps
        if (_currentStep >= 1)
          Positioned(
            bottom: -20,
            child: AnimatedOpacity(
              opacity: _currentStep >= 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 230),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessage() {
    return AnimatedSwitcher(
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
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Read',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
