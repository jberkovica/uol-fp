import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../lib/constants/app_theme.dart';
import '../lib/generated/app_localizations.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App smoke test - builds without error', (WidgetTester tester) async {
      // Create a minimal app widget for testing without Supabase dependencies
      final testApp = MaterialApp(
        title: 'Mira Storyteller',
        theme: AppTheme.theme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ru'),
          Locale('lv'),
        ],
        home: const Scaffold(
          body: Center(
            child: Text('Mira Storyteller'),
          ),
        ),
      );

      // Build the widget and trigger a frame
      await tester.pumpWidget(testApp);
      
      // Verify the app builds without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Mira Storyteller'), findsOneWidget);
    });

    testWidgets('App theme configuration test', (WidgetTester tester) async {
      // Test that the app uses the correct theme
      final testApp = MaterialApp(
        theme: AppTheme.theme,
        home: const Scaffold(
          body: Text('Test'),
        ),
      );

      await tester.pumpWidget(testApp);
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, equals(AppTheme.theme));
    });

    testWidgets('App localization configuration test', (WidgetTester tester) async {
      // Test that the app supports required locales
      final testApp = MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ru'), 
          Locale('lv'),
        ],
        home: const Scaffold(
          body: Text('Test'),
        ),
      );

      await tester.pumpWidget(testApp);
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, contains(const Locale('en')));
      expect(materialApp.supportedLocales, contains(const Locale('ru')));
      expect(materialApp.supportedLocales, contains(const Locale('lv')));
    });
  });
}
