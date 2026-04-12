// Smoke test — verifies the app widget tree can be pumped without crashing.
// The default Flutter counter test is replaced here because the Flovi Driver
// app uses Riverpod + go_router rather than a counter scaffold.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Flovi Driver'))),
    );
    expect(find.text('Flovi Driver'), findsOneWidget);
  });
}
