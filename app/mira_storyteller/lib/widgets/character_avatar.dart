import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Character types available in the app
enum CharacterType {
  hero1,
  hero2,
  cloud,
}

/// A widget for displaying character avatars in the app
class CharacterAvatar extends StatelessWidget {
  final double radius;
  final CharacterType characterType;

  const CharacterAvatar({
    super.key,
    required this.radius,
    required this.characterType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _getColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: _buildCharacterFace(),
      ),
    );
  }

  Color _getColor() {
    switch (characterType) {
      case CharacterType.hero1:
      case CharacterType.hero2:
        return AppColors.characterPurple;
      case CharacterType.cloud:
        return AppColors.characterCloud;
    }
  }

  Widget _buildCharacterFace() {
    switch (characterType) {
      case CharacterType.hero1:
        return _buildSmileWithClosedEyes();
      case CharacterType.hero2:
        return _buildSmileWithOpenEyes();
      case CharacterType.cloud:
        return _buildCloudFace();
    }
  }

  Widget _buildSmileWithClosedEyes() {
    final faceSize = radius * 2 * 0.6;
    
    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: Stack(
        children: [
          // Eyes (closed)
          Positioned(
            top: faceSize * 0.3,
            left: faceSize * 0.2,
            child: Container(
              width: faceSize * 0.2,
              height: faceSize * 0.05,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(faceSize * 0.025),
              ),
            ),
          ),
          
          Positioned(
            top: faceSize * 0.3,
            right: faceSize * 0.2,
            child: Container(
              width: faceSize * 0.2,
              height: faceSize * 0.05,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(faceSize * 0.025),
              ),
            ),
          ),
          
          // Smile
          Positioned(
            bottom: faceSize * 0.25,
            left: faceSize * 0.25,
            child: Container(
              width: faceSize * 0.5,
              height: faceSize * 0.25,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black,
                    width: faceSize * 0.05,
                  ),
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(faceSize * 0.25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmileWithOpenEyes() {
    final faceSize = radius * 2 * 0.6;
    
    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: Stack(
        children: [
          // Eyes (open)
          Positioned(
            top: faceSize * 0.25,
            left: faceSize * 0.2,
            child: Container(
              width: faceSize * 0.15,
              height: faceSize * 0.15,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Positioned(
            top: faceSize * 0.25,
            right: faceSize * 0.2,
            child: Container(
              width: faceSize * 0.15,
              height: faceSize * 0.15,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Mouth (small smile)
          Positioned(
            bottom: faceSize * 0.2,
            left: faceSize * 0.3,
            child: Container(
              width: faceSize * 0.4,
              height: faceSize * 0.15,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black,
                    width: faceSize * 0.05,
                  ),
                ),
                borderRadius: BorderRadius.circular(faceSize * 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudFace() {
    return Container(); // Placeholder for cloud face - will be implemented later
  }
}
