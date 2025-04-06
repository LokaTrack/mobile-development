// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatrack/features/delivery/screens/home_screen.dart';

void main() {
  testWidgets('Home screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Verify that the app title is displayed
    expect(find.text('LOKATRACK'), findsOneWidget);
    expect(find.text('Driver Delivery'), findsOneWidget);

    // Verify that the welcome message is displayed
    expect(find.text('Selamat Pagi,'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);

    // Verify that the bottom navigation bar items are present
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
