
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_mobile/main.dart';

void main() {
  testWidgets('Muestra la pantalla de inicio de sesión',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MiAplicacion());

    expect(find.text('Préstamo de equipos'), findsOneWidget);
    expect(
      find.text('Inicia sesión con tu cuenta institucional'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
