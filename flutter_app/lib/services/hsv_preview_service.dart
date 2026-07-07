import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/hsv_range.dart';
import '../models/roi_info.dart';
import '../models/video_info.dart';

class HsvPreviewFrame {
  final Uint8List bytes;
  final int width;
  final int height;

  const HsvPreviewFrame({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

class HsvPreviewResult {
  final Uint8List bytes;
  final int detectedPixels;
  final int totalPixels;

  const HsvPreviewResult({
    required this.bytes,
    required this.detectedPixels,
    required this.totalPixels,
  });

  double get detectedRatio =>
      totalPixels == 0 ? 0 : detectedPixels / totalPixels;
}

class HsvPreviewService {
  static const MethodChannel _channel = MethodChannel(
    'fault_diagnosis/hsv_preview',
  );

  Future<HsvPreviewFrame> loadRoiFrame({
    required VideoInfo videoInfo,
    required RoiInfo roiInfo,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final nativeResult = await _channel.invokeMapMethod<String, Object?>(
        'loadRoiFrame',
        <String, Object?>{
          'videoPath': videoInfo.path,
          'x': roiInfo.x,
          'y': roiInfo.y,
          'width': roiInfo.width,
          'height': roiInfo.height,
        },
      );
      if (nativeResult == null) {
        throw StateError('OpenCV ROI 프레임 결과가 없습니다.');
      }
      return HsvPreviewFrame(
        bytes: nativeResult['bytes'] as Uint8List,
        width: nativeResult['width'] as int,
        height: nativeResult['height'] as int,
      );
    }

    final path = videoInfo.path;
    if (path == null || path.isEmpty) {
      throw StateError('선택된 영상이 없습니다.');
    }

    final bytes = await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.PNG,
      timeMs: 0,
      maxWidth: 960,
      quality: 100,
    );

    if (bytes == null || bytes.isEmpty) {
      throw StateError('첫 프레임을 읽지 못했습니다.');
    }

    final cropped = await compute(_cropRoiFrame, <String, Object>{
      'bytes': bytes,
      'x': roiInfo.x,
      'y': roiInfo.y,
      'width': roiInfo.width,
      'height': roiInfo.height,
    });

    return HsvPreviewFrame(
      bytes: cropped['bytes'] as Uint8List,
      width: cropped['width'] as int,
      height: cropped['height'] as int,
    );
  }

  Future<HsvPreviewResult> applyHsvFilter({
    required Uint8List roiFrameBytes,
    required HsvRange hsvRange,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final nativeResult = await _channel.invokeMapMethod<String, Object?>(
        'applyHsvFilter',
        <String, Object?>{
          'bytes': roiFrameBytes,
          'hMin': hsvRange.hMin,
          'hMax': hsvRange.hMax,
          'sMin': hsvRange.sMin,
          'sMax': hsvRange.sMax,
          'vMin': hsvRange.vMin,
          'vMax': hsvRange.vMax,
        },
      );
      if (nativeResult == null) {
        throw StateError('OpenCV HSV 필터 결과가 없습니다.');
      }
      return HsvPreviewResult(
        bytes: nativeResult['bytes'] as Uint8List,
        detectedPixels: nativeResult['detectedPixels'] as int,
        totalPixels: nativeResult['totalPixels'] as int,
      );
    }

    final result = await compute(_applyHsvFilter, <String, Object>{
      'bytes': roiFrameBytes,
      'hMin': hsvRange.hMin,
      'hMax': hsvRange.hMax,
      'sMin': hsvRange.sMin,
      'sMax': hsvRange.sMax,
      'vMin': hsvRange.vMin,
      'vMax': hsvRange.vMax,
    });

    return HsvPreviewResult(
      bytes: result['bytes'] as Uint8List,
      detectedPixels: result['detectedPixels'] as int,
      totalPixels: result['totalPixels'] as int,
    );
  }
}

Map<String, Object> _cropRoiFrame(Map<String, Object> message) {
  final source = img.decodeImage(message['bytes'] as Uint8List);
  if (source == null) {
    throw StateError('첫 프레임 이미지를 해석하지 못했습니다.');
  }

  final roiX = message['x'] as double;
  final roiY = message['y'] as double;
  final roiWidth = message['width'] as double;
  final roiHeight = message['height'] as double;

  final left = (roiX * source.width).round().clamp(0, source.width - 1);
  final top = (roiY * source.height).round().clamp(0, source.height - 1);
  final right = ((roiX + roiWidth) * source.width).round().clamp(
        left + 1,
        source.width,
      );
  final bottom = ((roiY + roiHeight) * source.height).round().clamp(
        top + 1,
        source.height,
      );

  final cropped = img.copyCrop(
    source,
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );

  return <String, Object>{
    'bytes': Uint8List.fromList(img.encodePng(cropped)),
    'width': cropped.width,
    'height': cropped.height,
  };
}

Map<String, Object> _applyHsvFilter(Map<String, Object> message) {
  final source = img.decodeImage(message['bytes'] as Uint8List);
  if (source == null) {
    throw StateError('ROI 이미지를 해석하지 못했습니다.');
  }

  final hMin = message['hMin'] as double;
  final hMax = message['hMax'] as double;
  final sMin = message['sMin'] as double;
  final sMax = message['sMax'] as double;
  final vMin = message['vMin'] as double;
  final vMax = message['vMax'] as double;

  final output = img.Image(width: source.width, height: source.height);
  var detected = 0;

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();

      if (_isInHsvRange(
        red: red,
        green: green,
        blue: blue,
        hMin: hMin,
        hMax: hMax,
        sMin: sMin,
        sMax: sMax,
        vMin: vMin,
        vMax: vMax,
      )) {
        output.setPixelRgba(x, y, red, green, blue, 255);
        detected++;
      } else {
        output.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
  }

  return <String, Object>{
    'bytes': Uint8List.fromList(img.encodePng(output)),
    'detectedPixels': detected,
    'totalPixels': source.width * source.height,
  };
}

bool _isInHsvRange({
  required int red,
  required int green,
  required int blue,
  required double hMin,
  required double hMax,
  required double sMin,
  required double sMax,
  required double vMin,
  required double vMax,
}) {
  final maxChannel = math.max(red, math.max(green, blue)).toDouble();
  final minChannel = math.min(red, math.min(green, blue)).toDouble();
  final delta = maxChannel - minChannel;

  var hueDegrees = 0.0;
  if (delta != 0) {
    if (maxChannel == red) {
      hueDegrees = 60 * (((green - blue) / delta) % 6);
    } else if (maxChannel == green) {
      hueDegrees = 60 * (((blue - red) / delta) + 2);
    } else {
      hueDegrees = 60 * (((red - green) / delta) + 4);
    }
  }
  if (hueDegrees < 0) {
    hueDegrees += 360;
  }

  final openCvHue = hueDegrees / 2;
  final saturation = maxChannel == 0 ? 0 : (delta / maxChannel) * 255;
  final value = maxChannel;

  return openCvHue >= hMin &&
      openCvHue <= hMax &&
      saturation >= sMin &&
      saturation <= sMax &&
      value >= vMin &&
      value <= vMax;
}
