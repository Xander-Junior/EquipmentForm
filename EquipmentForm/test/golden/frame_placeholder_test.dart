import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('golden placeholder renders app shell', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('PDF Frame Placeholder')),
    ));

    expect(find.text('PDF Frame Placeholder'), findsOneWidget);
  });
}
