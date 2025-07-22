import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Responsive wrapper that constrains content width on larger screens
/// while maintaining full-width backgrounds
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerContent;
  
  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1200.0,
    this.padding,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // On small screens, use full width
    if (screenSize.width <= 600) {
      return child;
    }
    
    // On larger screens, constrain and center content
    Widget constrainedChild = Container(
      width: screenSize.width > maxWidth ? maxWidth : double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      child: child,
    );
    
    return centerContent 
        ? Center(child: constrainedChild)
        : constrainedChild;
  }
}

/// Responsive wrapper specifically for screen content with side padding
class ResponsiveScreenWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double sidePadding;
  
  const ResponsiveScreenWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1200.0,
    this.sidePadding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return ResponsiveWrapper(
      maxWidth: maxWidth,
      centerContent: true,
      padding: screenSize.width > 600 
          ? EdgeInsets.symmetric(horizontal: sidePadding)
          : null,
      child: child,
    );
  }
}

/// Responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.maxCrossAxisExtent = 200.0,
    this.mainAxisSpacing = 10.0,
    this.crossAxisSpacing = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

// Note: StandardScreenLayout removed - use AppTheme.screenHeader instead for consistency

/// Responsive breakpoint utilities
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < desktop;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktop;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width > mobile;
  }
  
  static int getColumnsForScreen(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    if (isMobile(context)) return mobileColumns;
    if (isTablet(context)) return tabletColumns;
    return desktopColumns;
  }
  
  /// Get responsive padding based on screen size
  static double getResponsivePadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    // Use provided values or defaults
    final mobilePadding = mobile ?? 20.0;
    final tabletPadding = tablet ?? 40.0;  
    final desktopPadding = desktop ?? 100.0;
    
    if (isMobile(context)) return mobilePadding;
    if (isTablet(context)) return tabletPadding;
    return desktopPadding;
  }
  
  /// Get responsive horizontal padding as EdgeInsets
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final padding = getResponsivePadding(context, 
      mobile: mobile, 
      tablet: tablet, 
      desktop: desktop
    );
    return EdgeInsets.symmetric(horizontal: padding);
  }
  
  /// Get responsive padding for all sides
  static EdgeInsets getResponsiveAllPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final padding = getResponsivePadding(context, 
      mobile: mobile, 
      tablet: tablet, 
      desktop: desktop
    );
    return EdgeInsets.all(padding);
  }
}