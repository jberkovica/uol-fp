/// Asset paths for Mira Storyteller app
class AppAssets {
  // SVG Images - Your provided assets
  static const String logo = 'assets/images/MIRA.svg';
  static const String miraReady = 'assets/images/mira-ready.svg';
  static const String miraWaiting = 'assets/images/mira-waiting.svg';
  static const String miraInClouds = 'assets/images/mira-in-clouds.svg';

  // Image paths for easy access
  static const String _imagePath = 'assets/images/';

  static String getImagePath(String fileName) => '$_imagePath$fileName';

  // Mascot states for different screens
  static const String mascotReady = miraReady; // For child home screen
  static const String mascotWaiting = miraWaiting; // For processing screen
  static const String mascotInClouds = miraInClouds; // For story display
  static const String appLogo = logo; // For splash screen and headers
}
