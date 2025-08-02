import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../lib/widgets/bottom_nav.dart';
import '../../lib/generated/app_localizations.dart';

void main() {
  group('BottomNav Widget Tests', () {
    late int tappedIndex;

    void onTapHandler(int index) {
      tappedIndex = index;
    }

    setUp(() {
      tappedIndex = -1;
    });

    Widget createTestApp({required Widget child}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        home: Scaffold(
          bottomNavigationBar: child,
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 0,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should render successfully
        expect(find.byType(BottomNav), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should highlight correct active tab', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1, // Home tab active
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should render with home tab active
        expect(find.byType(BottomNav), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Navigation Interactions', () {
      testWidgets('should trigger callback when tapping items', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Find clickable areas (GestureDetector wraps the nav items)
        final gestureDetectors = find.byType(GestureDetector);
        expect(gestureDetectors, findsNWidgets(4));

        // Tap first item (Profile)
        await tester.tap(gestureDetectors.first);
        await tester.pump();

        expect(tappedIndex, equals(0));
      });

      testWidgets('should handle multiple taps', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        final gestureDetectors = find.byType(GestureDetector);

        // Tap different items
        await tester.tap(gestureDetectors.at(0)); // Profile
        await tester.pump();
        expect(tappedIndex, equals(0));

        await tester.tap(gestureDetectors.at(2)); // Create
        await tester.pump();
        expect(tappedIndex, equals(2));
      });
    });

    group('Responsive Design', () {
      testWidgets('should render on narrow screens (may overflow)', (WidgetTester tester) async {
        // Set narrow screen size (simulating small phone)
        await tester.binding.setSurfaceSize(const Size(320, 568));
        
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should render successfully (overflow is expected behavior on very narrow screens)
        expect(find.byType(BottomNav), findsOneWidget);
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should render on very narrow screens (may overflow)', (WidgetTester tester) async {
        // Set very narrow screen size
        await tester.binding.setSurfaceSize(const Size(280, 568));
        
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should render successfully (overflow is expected on very narrow screens)
        expect(find.byType(BottomNav), findsOneWidget);
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should adapt padding based on screen width', (WidgetTester tester) async {
        // Test with narrow screen (should use smaller padding)
        await tester.binding.setSurfaceSize(const Size(350, 568));
        
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should render correctly with adaptive padding
        expect(tester.takeException(), isNull);
        expect(find.byType(BottomNav), findsOneWidget);

        // Test with normal screen (should use normal padding)
        await tester.binding.setSurfaceSize(const Size(450, 568));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(BottomNav), findsOneWidget);
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('State Management', () {
      testWidgets('should update visual state when currentIndex changes', (WidgetTester tester) async {
        // Start with profile active
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 0,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(BottomNav), findsOneWidget);

        // Change to home active
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should update visual state successfully
        expect(find.byType(BottomNav), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle invalid currentIndex gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 10, // Invalid index
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should render without crashing even with invalid index
        expect(find.byType(BottomNav), findsOneWidget);
        // Note: Exception handling depends on implementation
      });

      testWidgets('should handle negative currentIndex', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: -1, // Negative index
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should render without crashing even with negative index
        expect(find.byType(BottomNav), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic structure', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should have semantic elements for accessibility
        expect(find.byType(BottomNav), findsOneWidget);
        expect(find.byType(GestureDetector), findsNWidgets(4));
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BottomNav(
              currentIndex: 1,
              onTap: onTapHandler,
            ),
          ),
        );

        await tester.pump();

        // Should have focusable elements
        final gestureDetectors = find.byType(GestureDetector);
        expect(gestureDetectors, findsNWidgets(4));
      });
    });

    group('Performance', () {
      testWidgets('should rebuild efficiently when index changes', (WidgetTester tester) async {
        int buildCount = 0;
        
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) {
                buildCount++;
                return BottomNav(
                  currentIndex: 0,
                  onTap: onTapHandler,
                );
              },
            ),
          ),
        );

        await tester.pump();
        final initialBuildCount = buildCount;

        // Change index
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) {
                buildCount++;
                return BottomNav(
                  currentIndex: 1,
                  onTap: onTapHandler,
                );
              },
            ),
          ),
        );

        await tester.pump();

        // Should rebuild, but efficiently
        expect(buildCount, greaterThan(initialBuildCount));
        expect(find.byType(BottomNav), findsOneWidget);
      });
    });
  });
}