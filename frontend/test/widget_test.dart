// widget_test.dart — Smoke test: app launches and shows the splash screen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App launches and shows loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartParkApp());
    // SplashScreen renders a CircularProgressIndicator while resolving the route.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
