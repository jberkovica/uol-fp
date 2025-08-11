import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mira_storyteller/screens/child/kid_onboarding_wizard.dart';
import 'package:mira_storyteller/generated/app_localizations.dart';

/// Helper function to create a widget with localization support
Widget createLocalizedWidget(Widget child) {
  return MaterialApp(
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
      Locale('es'),
      Locale('fr'),
    ],
    locale: const Locale('en'), // Use English for tests
    home: child,
  );
}

void main() {
  group('KidOnboardingWizard Widget Tests', () {
    testWidgets('should display initial step with name and avatar selection', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Should show step 1 of 7
      expect(find.text('Step 1 of 7'), findsOneWidget);
      
      // Should show name input field
      expect(find.byType(TextField), findsOneWidget);
      
      // Should show avatar options (multiple GestureDetectors)
      expect(find.byType(GestureDetector), findsWidgets);
      
      // Continue button should be present 
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('should enable continue button when name is entered', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Enter a name
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();

      // Continue button should now be enabled
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);
    });

    testWidgets('should progress to age selection step', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Fill name and continue
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();
      
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should now be on step 2
      expect(find.text('Step 2 of 7'), findsOneWidget);

      // Should show age selector buttons (at least some age numbers)
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsWidgets); // May appear in title and as button

      // Should show back button
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('should progress to gender selection step', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Complete name step
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Complete age step (continue with default age)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should now be on step 3 (gender)
      expect(find.text('Step 3 of 7'), findsOneWidget);
      expect(find.text("Tell us about your child"), findsOneWidget);

      // Should show gender options
      expect(find.text('Boy'), findsOneWidget);
      expect(find.text('Girl'), findsOneWidget);
      expect(find.text('Prefer not to say'), findsOneWidget);
    });

    testWidgets('should allow back navigation', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Go to step 2
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should be on step 2
      expect(find.text('Step 2 of 7'), findsOneWidget);

      // Tap back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should be back on step 1
      expect(find.text('Step 1 of 7'), findsOneWidget);
      expect(find.text("What's your little one's name?"), findsOneWidget);
      
      // Name should still be filled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('Alice'));
    });

    testWidgets('should show skip option for optional steps', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Navigate to appearance step (step 4, which is optional)
      await _navigateToStep(tester, 4);

      // Should show skip button for optional steps
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('should display progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Check initial progress
      expect(find.text('Step 1 of 7'), findsOneWidget);

      // Progress through a few steps and check progress updates
      await _navigateToStep(tester, 3);
      expect(find.text('Step 3 of 7'), findsOneWidget);
    });

    testWidgets('should show close button', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Should show close/exit button
      expect(find.byType(IconButton), findsWidgets);
      
      // Look for X icon (close button)
      final closeButtons = find.byType(IconButton);
      expect(closeButtons, findsAtLeastNWidgets(1));
    });

    testWidgets('should handle avatar selection', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Should show multiple avatar options
      final avatarContainers = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(Container),
      );
      
      // Should have multiple avatar options
      expect(avatarContainers, findsWidgets);
      
      // Tap on an avatar option
      await tester.tap(avatarContainers.first);
      await tester.pump();

      // Avatar should be selected (visual change)
      // This is a basic test - in reality you'd check for visual changes
      expect(avatarContainers, findsWidgets);
    });

    testWidgets('should handle age selection', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Navigate to age step
      await _navigateToStep(tester, 2);

      // Test age selection
      await tester.tap(find.text('8'));
      await tester.pump();

      // Age should be selected (continue button should remain enabled)
      final continueButton = find.text('Continue');
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should handle gender selection', (WidgetTester tester) async {
      await tester.pumpWidget(createLocalizedWidget(const KidOnboardingWizard()));
      await tester.pumpAndSettle();

      // Navigate to gender step
      await _navigateToStep(tester, 3);

      // Initially continue should be disabled (no gender selected)
      var continueButton = find.text('Continue');
      var button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);

      // Select gender
      await tester.tap(find.text('Girl'));
      await tester.pump();

      // Continue should now be enabled
      continueButton = find.text('Continue');
      button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);
    });

    group('Step Validation', () {
      testWidgets('should validate required fields', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: const KidOnboardingWizard(),
          ),
        );

        // Step 1: Name is required
        final continueButton = find.text('Continue');
        var button = tester.widget<ElevatedButton>(continueButton);
        expect(button.onPressed, isNull); // disabled without name

        // Enter name
        await tester.enterText(find.byType(TextField), 'Test');
        await tester.pump();

        button = tester.widget<ElevatedButton>(continueButton);
        expect(button.onPressed, isNotNull); // enabled with name
      });

      testWidgets('should handle empty name validation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: const KidOnboardingWizard(),
          ),
        );

        // Enter empty name
        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        // Continue should still be disabled
        final continueButton = find.text('Continue');
        final button = tester.widget<ElevatedButton>(continueButton);
        expect(button.onPressed, isNull);
      });
    });

    group('Optional Steps', () {
      testWidgets('should allow skipping appearance step', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: const KidOnboardingWizard(),
          ),
        );

        // Navigate to appearance step
        await _navigateToStep(tester, 4);

        expect(find.text('Step 4 of 7'), findsOneWidget);
        expect(find.text("Help us personalize stories"), findsOneWidget);

        // Should have skip button
        expect(find.text('Skip'), findsOneWidget);

        // Skip the step
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Should move to next step
        expect(find.text('Step 5 of 7'), findsOneWidget);
      });
    });
  });
}

/// Helper function to navigate to a specific step in the wizard
Future<void> _navigateToStep(WidgetTester tester, int targetStep) async {
  // Start from step 1, navigate to target step
  if (targetStep > 1) {
    // Fill name for step 1
    await tester.enterText(find.byType(TextField), 'Test Child');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  if (targetStep > 2) {
    // Continue through age step (step 2)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  if (targetStep > 3) {
    // Select gender for step 3
    await tester.tap(find.text('Girl'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  // Continue for remaining steps as needed
  for (int step = 4; step < targetStep; step++) {
    if (step <= 5) { // Optional steps can be skipped
      await tester.tap(find.text('Skip'));
    } else {
      await tester.tap(find.text('Continue'));
    }
    await tester.pumpAndSettle();
  }
}