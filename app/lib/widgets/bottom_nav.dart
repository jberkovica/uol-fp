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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                strokeIcon: 'assets/icons/user.svg',
                filledIcon: 'assets/icons/user-filled.svg',
                label: AppLocalizations.of(context)!.profile,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                strokeIcon: 'assets/icons/home.svg',
                filledIcon: 'assets/icons/home-filled.svg',
                label: AppLocalizations.of(context)!.home,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                strokeIcon: 'assets/icons/circle-plus.svg',
                filledIcon: 'assets/icons/circle-plus-filled.svg',
                label: AppLocalizations.of(context)!.create,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                strokeIcon: 'assets/icons/settings.svg',
                filledIcon: 'assets/icons/settings-filled.svg',
                label: AppLocalizations.of(context)!.settings,
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
    // Adaptive padding based on screen width
    final double horizontalPadding = screenWidth < 400 ? 8 : 16;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SvgPicture.asset(
                isActive ? filledIcon : strokeIcon,
                key: ValueKey(isActive),
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isActive ? AppColors.primary : AppColors.textGrey, 
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.primary : AppColors.textGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}