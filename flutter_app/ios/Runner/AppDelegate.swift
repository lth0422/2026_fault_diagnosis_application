import AVFoundation
import Flutter
import UIKit

/// iOS 네이티브 호스트 진입점.
@main
@objc class AppDelegate: FlutterAppDelegate {
  private let displacementProgressHandler = AppDisplacementProgressStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerHsvPreviewChannel()
    registerDisplacementChannels()
    registerDiagnosisChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerHsvPreviewChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "fault_diagnosis/hsv_preview",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "loadRoiFrame":
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(code: "BAD_ARGS", message: "Invalid HSV preview arguments.", details: nil))
          return
        }

        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let output = try Self.loadRoiFrame(arguments: arguments)
            DispatchQueue.main.async {
              result(output)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "HSV_PREVIEW_FAILED",
                message: error.localizedDescription,
                details: nil
              ))
            }
          }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func loadRoiFrame(arguments: [String: Any]) throws -> [String: Any] {
    guard let videoPath = arguments["videoPath"] as? String, !videoPath.isEmpty else {
      throw NSError(
        domain: "HsvPreview",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "선택된 영상 경로가 없습니다."]
      )
    }

    let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .positiveInfinity
    generator.maximumSize = CGSize(width: 960, height: 960)

    let image = try generator.copyCGImage(at: .zero, actualTime: nil)
    let sourceWidth = image.width
    let sourceHeight = image.height

    let roiX = number(arguments["x"], fallback: 0.0)
    let roiY = number(arguments["y"], fallback: 0.0)
    let roiWidth = number(arguments["width"], fallback: 1.0)
    let roiHeight = number(arguments["height"], fallback: 1.0)

    let left = clamp(Int(roiX * Double(sourceWidth)), min: 0, max: sourceWidth - 1)
    let top = clamp(Int(roiY * Double(sourceHeight)), min: 0, max: sourceHeight - 1)
    let right = clamp(Int((roiX + roiWidth) * Double(sourceWidth)), min: left + 1, max: sourceWidth)
    let bottom = clamp(Int((roiY + roiHeight) * Double(sourceHeight)), min: top + 1, max: sourceHeight)

    guard let cropped = image.cropping(to: CGRect(
      x: left,
      y: top,
      width: right - left,
      height: bottom - top
    )) else {
      throw NSError(
        domain: "HsvPreview",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "첫 프레임 ROI를 자르지 못했습니다."]
      )
    }

    guard let pngData = UIImage(cgImage: cropped).pngData() else {
      throw NSError(
        domain: "HsvPreview",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "첫 프레임 이미지를 PNG로 변환하지 못했습니다."]
      )
    }

    return [
      "bytes": FlutterStandardTypedData(bytes: pngData),
      "width": cropped.width,
      "height": cropped.height,
    ]
  }

  private static func number(_ value: Any?, fallback: Double) -> Double {
    return (value as? NSNumber)?.doubleValue ?? fallback
  }

  private static func clamp(_ value: Int, min minValue: Int, max maxValue: Int) -> Int {
    return Swift.max(minValue, Swift.min(value, maxValue))
  }

  private func registerDiagnosisChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let diagnosisChannel = FlutterMethodChannel(
      name: "fault_diagnosis/model",
      binaryMessenger: controller.binaryMessenger
    )

    diagnosisChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "diagnose":
        guard let arguments = call.arguments as? [String: Any],
              let displacementZ = arguments["displacementZ"] as? [Any] else {
          result(FlutterError(code: "BAD_ARGS", message: "Invalid diagnosis arguments.", details: nil))
          return
        }

        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let output = try IOSDiagnosisCalculator.diagnose(withDisplacementZ: displacementZ)
            DispatchQueue.main.async {
              result(output)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "DIAGNOSIS_FAILED",
                message: error.localizedDescription,
                details: nil
              ))
            }
          }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerDisplacementChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let messenger = controller.binaryMessenger
    let displacementChannel = FlutterMethodChannel(
      name: "fault_diagnosis/displacement",
      binaryMessenger: messenger
    )
    let progressChannel = FlutterEventChannel(
      name: "fault_diagnosis/displacement_progress",
      binaryMessenger: messenger
    )
    progressChannel.setStreamHandler(displacementProgressHandler)

    displacementChannel.setMethodCallHandler { [weak self, weak controller] call, result in
      guard let self else {
        result(FlutterError(code: "UNAVAILABLE", message: "iOS channel is not available.", details: nil))
        return
      }

      switch call.method {
      case "computeDisplacement":
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(code: "BAD_ARGS", message: "Invalid displacement arguments.", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let output = try IOSDisplacementCalculator.compute(
              withArguments: arguments,
              progress: { progress in
                self.displacementProgressHandler.send(progress)
              }
            )

            DispatchQueue.main.async {
              result(output)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "DISPLACEMENT_FAILED",
                message: error.localizedDescription,
                details: nil
              ))
            }
          }
        }

      case "shareCsv":
        guard let arguments = call.arguments as? [String: Any],
              let csvUri = arguments["csvUri"] as? String,
              !csvUri.isEmpty else {
          result(FlutterError(code: "BAD_ARGS", message: "CSV path is missing.", details: nil))
          return
        }
        let url = csvUri.hasPrefix("file://")
          ? URL(string: csvUri)
          : URL(fileURLWithPath: csvUri)
        guard let url else {
          result(FlutterError(code: "BAD_ARGS", message: "Invalid CSV path.", details: csvUri))
          return
        }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller?.present(activity, animated: true) {
          result(true)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

private final class AppDisplacementProgressStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func send(_ progress: [AnyHashable: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(progress)
    }
  }
}
