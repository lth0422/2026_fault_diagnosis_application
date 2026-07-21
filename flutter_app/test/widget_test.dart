import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fault_diagnosis_application/app.dart';
import 'package:fault_diagnosis_application/models/diagnosis_session.dart';
import 'package:fault_diagnosis_application/models/video_info.dart';
import 'package:fault_diagnosis_application/pages/video_info_page.dart';

void main() {
  testWidgets('shows start page', (WidgetTester tester) async {
    await tester.pumpWidget(const FaultDiagnosisApp());

    expect(find.text('회전기계 베어링 결함 진단'), findsOneWidget);
    expect(find.text('결함 진단 시작하기', skipOffstage: false), findsOneWidget);
  });

  testWidgets('resolution preset updates width and height fields', (
    WidgetTester tester,
  ) async {
    final session = DiagnosisSession()
      ..setVideoInfo(const VideoInfo(width: 568, height: 320));

    await tester.pumpWidget(
      ChangeNotifierProvider<DiagnosisSession>.value(
        value: session,
        child: const MaterialApp(home: VideoInfoPage()),
      ),
    );

    await tester.tap(find.text('720 세로 (1280x720)'));
    await tester.pump();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, '1280');
    expect(fields[1].controller!.text, '720');
  });
}
