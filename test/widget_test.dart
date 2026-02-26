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
}
