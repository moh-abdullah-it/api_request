import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Posts app loads and displays mock data',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PostsApp());

    // Verify that the app title is displayed
    expect(find.text('Posts Demo (Mock)'), findsOneWidget);

    // Verify loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for mock data to load
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify that posts are displayed
    expect(find.byType(ListView), findsOneWidget);

    // Verify demo mode banner is shown
    expect(find.text('Demo Mode: Using mock data (network requests disabled)'),
        findsOneWidget);

    // Verify at least one post card is displayed
    expect(find.text('Welcome to API Request Package'), findsOneWidget);
  });

  testWidgets('Post card tap navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(const PostsApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap on the first post
    await tester.tap(find.text('Welcome to API Request Package'));
    await tester.pumpAndSettle();

    // Verify navigation to detail screen
    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Welcome to API Request Package'), findsOneWidget);
  });

  testWidgets('Data source info dialog works', (WidgetTester tester) async {
    await tester.pumpWidget(const PostsApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap the data source info icon in the app bar (not the banner)
    await tester.tap(find.byIcon(Icons.offline_bolt).last);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Data Source'), findsOneWidget);
    expect(find.textContaining('Currently using mock data'), findsOneWidget);
  });
}
