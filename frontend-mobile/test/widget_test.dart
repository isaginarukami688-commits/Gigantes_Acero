import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_mobile/main.dart';

void main() {
  testWidgets('La aplicación inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MiAplicacion());
    await tester.pump();

    expect(find.byType(MiAplicacion), findsOneWidget);
  });
}
