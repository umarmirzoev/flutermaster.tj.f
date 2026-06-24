import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masterchas_app/main.dart';

void main() {
  testWidgets('App starts on splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasterChasApp()));
    await tester.pump();

    expect(find.text('Master.tj'), findsOneWidget);
    expect(find.text('для клиентов'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}
