import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'constants/app_theme.dart';
import 'screens/child/splash_screen.dart';
import 'screens/child/profile_select_screen.dart';
import 'screens/child/child_home_screen.dart';
import 'screens/child/processing_screen.dart';
import 'screens/child/story_display_screen.dart';
import 'screens/parent/parent_login_screen.dart';
import 'screens/parent/parent_dashboard_screen.dart';
import 'screens/parent/story_preview_screen.dart';
import 'services/ai_story_service.dart';

void main() async {
  // Ensure that Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from root .env file
  await dotenv.load(fileName: "../.env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize our real AI story service
  AIStoryService().initialize();
  runApp(const MiraStorytellerApp());
}

class MiraStorytellerApp extends StatelessWidget {
  const MiraStorytellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mira Storyteller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
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
