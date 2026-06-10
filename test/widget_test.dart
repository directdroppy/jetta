import 'package:flutter_test/flutter_test.dart';

import 'package:jetta/main.dart';

void main() {
  testWidgets('rol seçim ekranı açılır', (WidgetTester tester) async {
    await tester.pumpWidget(const JettaApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('JETTA'), findsOneWidget);
    expect(find.text('Yük Verenim'), findsOneWidget);
    expect(find.text('Şoförüm / Nakliyeciyim'), findsOneWidget);
  });
}
