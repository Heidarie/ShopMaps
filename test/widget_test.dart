import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shopmaps/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts and shows shopping action', (tester) async {
    await tester.pumpWidget(const ShopMapsApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.shopping_cart_checkout), findsOneWidget);
  });

  testWidgets('Account icon opens groups and login screen', (tester) async {
    await tester.pumpWidget(const ShopMapsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Local mode'), findsOneWidget);
  });
}
