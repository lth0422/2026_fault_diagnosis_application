import Flutter
import UIKit

/// iOS 네이티브 호스트 진입점.
///
/// ⚠️ 1차 마일스톤에서는 커스텀 MethodChannel 을 구현하지 않는다.
/// 향후 변위 추출 / 모델 추론 관련 iOS 네이티브 코드(Core ML 등)는
/// 이 `ios/` 폴더 하위에 추가한다.
/// (Dart 측 채널 래퍼: lib/platform/native_*_channel.dart)
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
