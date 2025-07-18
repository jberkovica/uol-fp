import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'constants/app_theme.dart';
import 'screens/child/splash_screen.dart';
import 'screens/child/profile_select_screen.dart';
import 'screens/child/child_home_screen.dart';
import 'screens/child/profile_screen.dart';
import 'screens/child/processing_screen.dart';
import 'screens/child/story_display_screen.dart';
import 'screens/parent/parent_login_screen.dart';
import 'screens/parent/pin_entry_screen.dart';
import 'screens/parent/parent_dashboard_main.dart';
import 'screens/parent/story_preview_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'services/ai_story_service.dart';
import 'services/app_state_service.dart';

void main() async {
  // Ensure that Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from root .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } else {
    throw Exception('Supabase configuration missing. Please check your .env file.');
  }

  // Initialize our real AI story service
  AIStoryService().initialize();
  
  // Initialize app state service for local storage
  await AppStateService.init();
  
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
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile-select': (context) => const ProfileSelectScreen(),
        '/child-home': (context) => const ChildHomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/story-display': (context) => const StoryDisplayScreen(),
        '/parent-login': (context) => const ParentLoginScreen(),
        '/parent-dashboard': (context) => const PinEntryScreen(),
        '/parent-dashboard-main': (context) => const ParentDashboardMain(),
        '/story-preview': (context) => const StoryPreviewScreen(),
      },
    );
  }
}
