import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mira_storyteller/generated/app_localizations.dart';

/// Test widget localization functionality
void main() {
  group('Widget Localization Tests', () {
    testWidgets('AppLocalizations should load for all supported locales', (tester) async {
      // Test English
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('lv'), 
            Locale('ru'),
            Locale('es'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text('Title: ${l10n?.appTitle ?? 'NOT_FOUND'}'),
                    Text('Create: ${l10n?.create ?? 'NOT_FOUND'}'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Title: Mira Storyteller'), findsOneWidget);
      expect(find.textContaining('Create: create'), findsOneWidget);
      expect(find.textContaining('NOT_FOUND'), findsNothing);
    });
    
    testWidgets('Should handle Latvian locale correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('lv'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('lv'), 
            Locale('ru'),
            Locale('es'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text('App: ${l10n?.appTitle ?? 'NOT_FOUND'}'),
                    Text('Latest: ${l10n?.latest ?? 'NOT_FOUND'}'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Check that we got actual Latvian translations
      expect(find.textContaining('Mira Stāstniece'), findsOneWidget,
        reason: 'Should display Latvian app title');
      expect(find.textContaining('Jaunākie'), findsOneWidget,
        reason: 'Should display Latvian text for latest');
      expect(find.textContaining('NOT_FOUND'), findsNothing);
    });
    
    testWidgets('Should handle Russian locale correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('lv'), 
            Locale('ru'),
            Locale('es'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text('App: ${l10n?.appTitle ?? 'NOT_FOUND'}'),
                    Text('Favourites: ${l10n?.favourites ?? 'NOT_FOUND'}'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Check that we got actual Russian translations
      expect(find.textContaining('Мира Сказочница'), findsOneWidget,
        reason: 'Should display Russian app title');
      expect(find.textContaining('Любимые'), findsOneWidget,
        reason: 'Should display Russian text for favourites');
      expect(find.textContaining('NOT_FOUND'), findsNothing);
    });
    
    testWidgets('Should fallback to English for unsupported locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'), // German - not supported
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('lv'), 
            Locale('ru'),
            Locale('es'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Text('App: ${l10n?.appTitle ?? 'NOT_FOUND'}'),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should fallback to English
      expect(find.textContaining('App: Mira Storyteller'), findsOneWidget);
      expect(find.textContaining('NOT_FOUND'), findsNothing);
    });
    
    testWidgets('Should handle parameterized translations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('lv'), 
            Locale('ru'),
            Locale('es'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n?.kidStories('Alice') ?? 'NOT_FOUND'),
                    Text(l10n?.stories(5) ?? 'NOT_FOUND'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.textContaining("Alice's stories"), findsOneWidget);
      expect(find.textContaining('5 stories'), findsOneWidget);
      expect(find.textContaining('NOT_FOUND'), findsNothing);
    });

    testWidgets('Should handle Spanish locale correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('lv'), 
            Locale('ru'),
            Locale('es'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text('App: ${l10n?.appTitle ?? 'NOT_FOUND'}'),
                    Text('Create: ${l10n?.create ?? 'NOT_FOUND'}'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Check that we got actual Spanish translations
      expect(find.textContaining('Mira Cuentacuentos'), findsOneWidget,
        reason: 'Should display Spanish app title');
      expect(find.textContaining('crear'), findsOneWidget,
        reason: 'Should display Spanish text for create');
      expect(find.textContaining('NOT_FOUND'), findsNothing);
    });

    testWidgets('Should handle French locale correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('lv'), 
            Locale('ru'),
            Locale('es'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text('App: ${l10n?.appTitle ?? 'NOT_FOUND'}'),
                    Text('Create: ${l10n?.create ?? 'NOT_FOUND'}'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Check that we got actual French translations
      expect(find.textContaining('Mira Conteuse'), findsOneWidget,
        reason: 'Should display French app title');
      expect(find.textContaining('créer'), findsOneWidget,
        reason: 'Should display French text for create');
      expect(find.textContaining('NOT_FOUND'), findsNothing);
    });
  });
}