import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Profile picture types available for kids
enum ProfileType {
  profile1,
  profile2,
  profile3,
  profile4,
}

/// A widget for displaying kid profile pictures using actual images
class ProfileAvatar extends StatelessWidget {
  final double radius;
  final ProfileType profileType;

  const ProfileAvatar({
    super.key,
    required this.radius,
    required this.profileType,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
          _getImagePath(),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to person icon if image fails to load
            // Fallback to colored circle if image fails to load
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: _getFallbackColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: radius,
                color: AppColors.white,
              ),
            );
          },
        ),
    );
  }

  String _getImagePath() {
    String path;
    switch (profileType) {
      case ProfileType.profile1:
        path = 'assets/images/user-profile/profile-img-1-256.png';
        break;
      case ProfileType.profile2:
        path = 'assets/images/user-profile/profile-img-2-256.png';
        break;
      case ProfileType.profile3:
        path = 'assets/images/user-profile/profile-img-3-256.png';
        break;
      case ProfileType.profile4:
        path = 'assets/images/user-profile/profile-img-4-256.png';
        break;
    }
    return path;
  }

  Color _getFallbackColor() {
    switch (profileType) {
      case ProfileType.profile1:
        return AppColors.primary;
      case ProfileType.profile2:
        return AppColors.secondary;
      case ProfileType.profile3:
        return AppColors.success;
      case ProfileType.profile4:
        return AppColors.orange;
    }
  }

  /// Convert from string avatar type to ProfileType enum
  static ProfileType fromString(String avatarType) {
    switch (avatarType) {
      case 'profile1':
        return ProfileType.profile1;
      case 'profile2':
        return ProfileType.profile2;
      case 'profile3':
        return ProfileType.profile3;
      case 'profile4':
        return ProfileType.profile4;
      default:
        return ProfileType.profile1;
    }
  }

  /// Convert ProfileType enum to string
  static String typeToString(ProfileType profileType) {
    return profileType.toString().split('.').last;
  }
}