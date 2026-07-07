import 'package:flutter_test/flutter_test.dart';

import 'package:fault_diagnosis_application/app.dart';

void main() {
  testWidgets('shows start page', (WidgetTester tester) async {
    await tester.pumpWidget(const FaultDiagnosisApp());

    expect(find.text('회전기계 베어링 결함 진단'), findsOneWidget);
    expect(find.text('결함 진단 시작하기', skipOffstage: false), findsOneWidget);
  });
}
