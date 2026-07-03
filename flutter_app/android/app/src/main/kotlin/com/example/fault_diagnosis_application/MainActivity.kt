package com.example.fault_diagnosis_application

import io.flutter.embedding.android.FlutterActivity

/**
 * Android 네이티브 호스트 진입점.
 *
 * ⚠️ 1차 마일스톤에서는 커스텀 MethodChannel 을 구현하지 않는다.
 * 향후 변위 추출 / 모델 추론 관련 Android 네이티브 코드는 이 패키지 하위에 추가한다.
 * (Dart 측 채널 래퍼: lib/platform/native_*_channel.dart)
 */
class MainActivity : FlutterActivity()
