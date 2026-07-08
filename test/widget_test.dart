import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simats_campusnav/main.dart';

void main() {
  testWidgets('App Initial Load and Splash Screen Test', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    await tester.pumpWidget(const CampusNavApp());

    // 2. Verify that Splash Screen shows the App Name
    expect(find.text('SIMATS'), findsOneWidget);
    expect(find.text('Campus Nav'), findsOneWidget);

    // 3. Verify that the "Get Started" button is present
    expect(find.text('Get Started'), findsOneWidget);

    // 4. Tap the "Get Started" button and trigger transition
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle(); // Wait for navigation animation to finish

    // 5. Verify that we are now on the Login Screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to continue'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email and Password fields
  });

  testWidgets('Login Screen UI Elements Test', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusNavApp());
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Check for essential UI elements
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });
}
