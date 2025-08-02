import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.lightGrey,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 350 ? 4 : 12, 
            vertical: 8
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 0,
                  strokeIcon: 'assets/icons/user.svg',
                  filledIcon: 'assets/icons/user-filled.svg',
                  label: AppLocalizations.of(context)!.profile,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 1,
                  strokeIcon: 'assets/icons/home.svg',
                  filledIcon: 'assets/icons/home-filled.svg',
                  label: AppLocalizations.of(context)!.home,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 2,
                  strokeIcon: 'assets/icons/circle-plus.svg',
                  filledIcon: 'assets/icons/circle-plus-filled.svg',
                  label: AppLocalizations.of(context)!.create,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 3,
                  strokeIcon: 'assets/icons/settings.svg',
                  filledIcon: 'assets/icons/settings-filled.svg',
                  label: AppLocalizations.of(context)!.settings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String strokeIcon,
    required String filledIcon,
    required String label,
  }) {
    final bool isActive = currentIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // More aggressive responsive adjustments
    final double iconSize = screenWidth < 350 ? 20 : 24;
    final double fontSize = screenWidth < 350 ? 10 : 12;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 350 ? 2 : 4,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SvgPicture.asset(
                isActive ? filledIcon : strokeIcon,
                key: ValueKey(isActive),
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(
                  isActive ? AppColors.primary : AppColors.textGrey, 
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(height: screenWidth < 350 ? 2 : 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.primary : AppColors.textGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: fontSize,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}