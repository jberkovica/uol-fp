import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'screens/child/splash_screen.dart';
import 'screens/child/profile_select_screen.dart';
import 'screens/child/child_home_screen.dart';
import 'screens/child/processing_screen.dart';
import 'screens/child/story_display_screen.dart';
import 'screens/parent/parent_login_screen.dart';
import 'screens/parent/parent_dashboard_screen.dart';
import 'screens/parent/story_preview_screen.dart';
import 'services/mock_story_service.dart';

void main() {
  // Initialize our mock story service with sample data
  MockStoryService().initialize();
  runApp(const MiraStorytellerApp());
}

class MiraStorytellerApp extends StatelessWidget {
  const MiraStorytellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mira Storyteller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/profile-select': (context) => const ProfileSelectScreen(),
        '/child-home': (context) => const ChildHomeScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/story-display': (context) => const StoryDisplayScreen(),
        '/parent-login': (context) => const ParentLoginScreen(),
        '/parent-dashboard': (context) => const ParentDashboardScreen(),
        '/story-preview': (context) => const StoryPreviewScreen(),
      },
    );
  }
}
