import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Character types available in the app
enum CharacterType {
  hero1,
  hero2,
  cloud,
}

/// A widget for displaying character avatars in the app - FLAT DESIGN
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
        // NO shadows - completely flat design
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
        return AppColors.primary; // Use the primary purple color
      case CharacterType.cloud:
        return AppColors.lightGrey; // Use light grey for cloud
    }
  }

  Widget _buildCharacterFace() {
    switch (characterType) {
      case CharacterType.hero1:
        return _buildFriendlyFace();
      case CharacterType.hero2:
        return _buildHappyFace();
      case CharacterType.cloud:
        return _buildCloudFace();
    }
  }

  Widget _buildFriendlyFace() {
    final faceSize = radius * 2 * 0.6;

    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: Stack(
        children: [
          // Left eye (friendly dot)
          Positioned(
            top: faceSize * 0.3,
            left: faceSize * 0.25,
            child: Container(
              width: faceSize * 0.12,
              height: faceSize * 0.12,
              decoration: const BoxDecoration(
                color: AppColors.textLight,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Right eye (friendly dot)
          Positioned(
            top: faceSize * 0.3,
            right: faceSize * 0.25,
            child: Container(
              width: faceSize * 0.12,
              height: faceSize * 0.12,
              decoration: const BoxDecoration(
                color: AppColors.textLight,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Simple smile (small oval)
          Positioned(
            bottom: faceSize * 0.3,
            left: faceSize * 0.35,
            right: faceSize * 0.35,
            child: Container(
              height: faceSize * 0.08,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(faceSize * 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHappyFace() {
    final faceSize = radius * 2 * 0.6;

    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: Stack(
        children: [
          // Left eye (slightly bigger dot)
          Positioned(
            top: faceSize * 0.28,
            left: faceSize * 0.25,
            child: Container(
              width: faceSize * 0.15,
              height: faceSize * 0.15,
              decoration: const BoxDecoration(
                color: AppColors.textLight,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Right eye (slightly bigger dot)
          Positioned(
            top: faceSize * 0.28,
            right: faceSize * 0.25,
            child: Container(
              width: faceSize * 0.15,
              height: faceSize * 0.15,
              decoration: const BoxDecoration(
                color: AppColors.textLight,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Happy smile (wider oval)
          Positioned(
            bottom: faceSize * 0.25,
            left: faceSize * 0.25,
            right: faceSize * 0.25,
            child: Container(
              height: faceSize * 0.1,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(faceSize * 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudFace() {
    final faceSize = radius * 2 * 0.6;

    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: Stack(
        children: [
          // Sleepy eyes (small ovals)
          Positioned(
            top: faceSize * 0.35,
            left: faceSize * 0.25,
            child: Container(
              width: faceSize * 0.15,
              height: faceSize * 0.08,
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(faceSize * 0.04),
              ),
            ),
          ),

          Positioned(
            top: faceSize * 0.35,
            right: faceSize * 0.25,
            child: Container(
              width: faceSize * 0.15,
              height: faceSize * 0.08,
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(faceSize * 0.04),
              ),
            ),
          ),

          // Peaceful smile
          Positioned(
            bottom: faceSize * 0.3,
            left: faceSize * 0.4,
            right: faceSize * 0.4,
            child: Container(
              height: faceSize * 0.06,
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(faceSize * 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
