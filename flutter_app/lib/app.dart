import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/diagnosis_session.dart';
import 'pages/start_page.dart';
import 'pages/video_select_page.dart';
import 'pages/video_info_page.dart';
import 'pages/roi_setting_page.dart';
import 'pages/marker_color_page.dart';
import 'pages/hsv_setting_page.dart';
import 'pages/marker_center_page.dart';
import 'pages/displacement_page.dart';
import 'pages/fault_diagnosis_page.dart';

/// 앱 루트 위젯.
///
/// - [DiagnosisSession]을 앱 전역에 제공(provider).
/// - named route 기반 네비게이션으로 9단계 화면 흐름을 구성한다.
class FaultDiagnosisApp extends StatelessWidget {
  const FaultDiagnosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DiagnosisSession>(
      create: (_) => DiagnosisSession(),
      child: MaterialApp(
        title: 'Fault Diagnosis',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        initialRoute: StartPage.routeName,
        routes: {
          StartPage.routeName: (_) => const StartPage(),
          VideoSelectPage.routeName: (_) => const VideoSelectPage(),
          VideoInfoPage.routeName: (_) => const VideoInfoPage(),
          RoiSettingPage.routeName: (_) => const RoiSettingPage(),
          MarkerColorPage.routeName: (_) => const MarkerColorPage(),
          HsvSettingPage.routeName: (_) => const HsvSettingPage(),
          MarkerCenterPage.routeName: (_) => const MarkerCenterPage(),
          DisplacementPage.routeName: (_) => const DisplacementPage(),
          FaultDiagnosisPage.routeName: (_) => const FaultDiagnosisPage(),
        },
      ),
    );
  }
}
