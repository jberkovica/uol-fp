import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'generated/app_localizations.dart';
import 'config/supabase_config.dart';
import 'constants/app_theme.dart';
import 'constants/app_colors.dart';
import 'screens/child/splash_screen.dart';
import 'screens/child/profile_select_screen.dart';
import 'screens/child/child_home_screen.dart';
import 'screens/child/profile_screen.dart';
import 'screens/child/upload_screen.dart';
import 'screens/child/processing_screen.dart';
import 'screens/child/story_display_screen.dart';
import 'screens/parent/pin_entry_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/parent/change_pin_screen.dart';
import 'screens/parent/story_preview_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/pin_setup_screen.dart';
import 'services/ai_story_service.dart';
import 'services/app_state_service.dart';
import 'services/language_service.dart';
import 'services/auth_service.dart';
import 'services/logging_service.dart';
import 'services/analytics_service.dart';

void main() async {
  // Ensure that Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from root .env file (symlinked)
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Crashlytics (production only)
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

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
  
  // Initialize language service
  await LanguageService.instance.initialize();
  
  // Initialize analytics service
  await AnalyticsService.initialize();
  
  // Logging is now automatically initialized when first used
  
  final logger = LoggingService.getLogger('main');
  logger.i('Starting Mira Storyteller app');
  
  runApp(const MiraStorytellerApp());
}

class MiraStorytellerApp extends StatefulWidget {
  const MiraStorytellerApp({super.key});

  @override
  State<MiraStorytellerApp> createState() => _MiraStorytellerAppState();
}

class _MiraStorytellerAppState extends State<MiraStorytellerApp> {
  late final StreamSubscription<AuthState> _authSubscription;
  
  @override
  void initState() {
    super.initState();
    // Monitor auth state changes for OAuth logging and language sync
    _authSubscription = AuthService.instance.authStateChanges.listen((authState) {
      final logger = LoggingService.getLogger('AuthStateListener');
      
      if (authState.event == AuthChangeEvent.signedIn) {
        // OAuth/email sign-in successful
        logger.i('User signed in successfully'); // User email not logged for privacy
        
        // Sync language from server after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          LanguageService.instance.syncFromServer();
        });
      } else if (authState.event == AuthChangeEvent.signedOut) {
        // User signed out - could optionally reset to system language
        // For now, keep the last selected language
        logger.i('User signed out');
      }
    });
  }
  
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, child) {
        // Wait for LanguageService to be fully initialized before showing UI
        if (!LanguageService.instance.isInitialized) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.primary,
              body: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              ),
            ),
          );
        }
        
        return MaterialApp(
          title: 'Mira Storyteller',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          
          // Dynamic locale from LanguageService
          locale: LanguageService.instance.currentLocale,
          
          // Localization configuration
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LanguageService.supportedLocales,
          
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/otp-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return OTPVerificationScreen(
                email: args?['email'] ?? '',
                password: args?['password'] ?? '',
                fullName: args?['fullName'],
              );
            },
            '/pin-setup': (context) => const PinSetupScreen(),
            '/profile-select': (context) => const ProfileSelectScreen(),
            '/child-home': (context) => const ChildHomeScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/upload': (context) => const UploadScreen(),
            '/processing': (context) => const ProcessingScreen(),
            '/story-display': (context) => const StoryDisplayScreen(),
            '/parent-dashboard': (context) => const PinEntryScreen(),
            '/parent-dashboard-main': (context) => const ParentDashboardMain(),
            '/change-pin': (context) => const ChangePinScreen(),
            '/story-preview': (context) => const StoryPreviewScreen(),
          },
        );
      },
    );
  }
}
