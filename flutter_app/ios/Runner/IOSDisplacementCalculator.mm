#import "IOSDisplacementCalculator.h"

#import <opencv2/core.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/videoio.hpp>

static const NSInteger IOSModelInputLength = 2048;

static NSError *IOSDisplacementError(NSString *message) {
  return [NSError errorWithDomain:@"IOSDisplacementCalculator"
                             code:1
                         userInfo:@{NSLocalizedDescriptionKey: message}];
}

static double NumberValue(NSDictionary<NSString *, id> *arguments, NSString *key, double fallback) {
  id value = arguments[key];
  return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : fallback;
}

static NSString *StringValue(NSDictionary<NSString *, id> *arguments, NSString *key) {
  id value = arguments[key];
  return [value isKindOfClass:[NSString class]] ? value : @"";
}

static int ClampInt(int value, int minValue, int maxValue) {
  return std::max(minValue, std::min(value, maxValue));
}

static std::vector<double> ResizeSeries(const std::vector<double> &values, NSInteger targetLength) {
  std::vector<double> output;
  output.reserve(targetLength);

  if (values.empty()) {
    output.assign(targetLength, 0.0);
    return output;
  }
  if (values.size() == 1) {
    output.assign(targetLength, values[0]);
    return output;
  }
  if ((NSInteger)values.size() == targetLength) {
    return values;
  }

  double scale = (double)(values.size() - 1) / (double)(targetLength - 1);
  for (NSInteger i = 0; i < targetLength; i++) {
    double sourceIndex = i * scale;
    NSInteger left = (NSInteger)floor(sourceIndex);
    NSInteger right = std::min<NSInteger>(left + 1, (NSInteger)values.size() - 1);
    double fraction = sourceIndex - left;
    output.push_back(values[left] * (1.0 - fraction) + values[right] * fraction);
  }
  return output;
}

static double StandardDeviation(const std::vector<double> &values) {
  if (values.empty()) {
    return 0.0;
  }
  double sum = 0.0;
  for (double value : values) {
    sum += value;
  }
  double average = sum / values.size();
  double variance = 0.0;
  for (double value : values) {
    double diff = value - average;
    variance += diff * diff;
  }
  return sqrt(variance / values.size());
}

static NSArray<NSNumber *> *ArrayFromVector(const std::vector<double> &values) {
  NSMutableArray<NSNumber *> *array = [NSMutableArray arrayWithCapacity:values.size()];
  for (double value : values) {
    [array addObject:@(value)];
  }
  return array;
}

static cv::Point2d DetectMarkerCenterWithColor(const cv::Mat &source,
                                               int colorConversionCode,
                                               double hMin,
                                               double hMax,
                                               double sMin,
                                               double sMax,
                                               double vMin,
                                               double vMax,
                                               bool *found) {
  cv::Mat hsvMat;
  cv::Mat mask;
  cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5));

  cv::cvtColor(source, hsvMat, colorConversionCode);
  cv::inRange(hsvMat, cv::Scalar(hMin, sMin, vMin), cv::Scalar(hMax, sMax, vMax), mask);
  cv::morphologyEx(mask, mask, cv::MORPH_OPEN, kernel);
  cv::morphologyEx(mask, mask, cv::MORPH_CLOSE, kernel);

  cv::Moments moments = cv::moments(mask);
  if (moments.m00 == 0.0) {
    *found = false;
    return cv::Point2d();
  }

  *found = true;
  return cv::Point2d(moments.m10 / moments.m00, moments.m01 / moments.m00);
}

static cv::Point2d DetectMarkerCenter(const cv::Mat &source,
                                      double hMin,
                                      double hMax,
                                      double sMin,
                                      double sMax,
                                      double vMin,
                                      double vMax,
                                      bool *found) {
  cv::Point2d center = DetectMarkerCenterWithColor(
      source, cv::COLOR_BGR2HSV, hMin, hMax, sMin, sMax, vMin, vMax, found);
  if (*found) {
    return center;
  }
  return DetectMarkerCenterWithColor(
      source, cv::COLOR_RGB2HSV, hMin, hMax, sMin, sMax, vMin, vMax, found);
}

static NSString *SaveCsv(const std::vector<double> &displacementX,
                         const std::vector<double> &displacementZ,
                         double fps,
                         NSString **displayName,
                         NSError **error) {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyyMMdd_HHmmss";
  NSString *fileName = [NSString stringWithFormat:@"displacement_%@.csv", [formatter stringFromDate:[NSDate date]]];

  NSArray<NSURL *> *documentUrls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                          inDomains:NSUserDomainMask];
  NSURL *documentsUrl = documentUrls.firstObject;
  if (documentsUrl == nil) {
    if (error != nil) {
      *error = IOSDisplacementError(@"Documents 디렉터리를 찾지 못했습니다.");
    }
    return nil;
  }

  NSURL *fileUrl = [documentsUrl URLByAppendingPathComponent:fileName];
  NSMutableString *csv = [NSMutableString string];
  [csv appendFormat:@"# FPS: %.6f\n", fps];
  [csv appendString:@"Frame,Time(s),DisplacementX(px),DisplacementZ(px)\n"];
  for (NSUInteger index = 0; index < displacementZ.size(); index++) {
    double x = index < displacementX.size() ? displacementX[index] : 0.0;
    double z = displacementZ[index];
    double time = fps > 0 ? (double)index / fps : 0.0;
    [csv appendFormat:@"%lu,%.9f,%.9f,%.9f\n", (unsigned long)index, time, x, z];
  }

  NSError *writeError = nil;
  if (![csv writeToURL:fileUrl atomically:YES encoding:NSUTF8StringEncoding error:&writeError]) {
    if (error != nil) {
      *error = writeError ?: IOSDisplacementError(@"CSV 파일을 저장하지 못했습니다.");
    }
    return nil;
  }

  if (displayName != nil) {
    *displayName = [NSString stringWithFormat:@"Documents/%@", fileName];
  }
  return fileUrl.path;
}

@implementation IOSDisplacementCalculator

+ (NSDictionary<NSString *, id> *)computeWithArguments:(NSDictionary<NSString *, id> *)arguments
                                              progress:(IOSDisplacementProgressBlock)progress
                                                 error:(NSError **)error {
  NSString *videoPath = StringValue(arguments, @"videoPath");
  if (videoPath.length == 0) {
    if (error != nil) {
      *error = IOSDisplacementError(@"선택된 영상 경로가 없습니다.");
    }
    return nil;
  }

  double roiX = NumberValue(arguments, @"roiX", 0.0);
  double roiY = NumberValue(arguments, @"roiY", 0.0);
  double roiWidth = NumberValue(arguments, @"roiWidth", 0.0);
  double roiHeight = NumberValue(arguments, @"roiHeight", 0.0);
  double hMin = NumberValue(arguments, @"hMin", 0.0);
  double hMax = NumberValue(arguments, @"hMax", 180.0);
  double sMin = NumberValue(arguments, @"sMin", 0.0);
  double sMax = NumberValue(arguments, @"sMax", 255.0);
  double vMin = NumberValue(arguments, @"vMin", 0.0);
  double vMax = NumberValue(arguments, @"vMax", 255.0);
  double markerX = NumberValue(arguments, @"markerX", 0.0);
  double markerY = NumberValue(arguments, @"markerY", 0.0);
  double markerXRatio = NumberValue(arguments, @"markerXRatio", -1.0);
  double markerYRatio = NumberValue(arguments, @"markerYRatio", -1.0);
  double trackingBoxSize = NumberValue(arguments, @"trackingBoxSize", 48.0);
  double trackingBoxSizeRatio = NumberValue(arguments, @"trackingBoxSizeRatio", -1.0);
  double fps = NumberValue(arguments, @"fps", 30.0);
  if (fps <= 0.0) {
    fps = 30.0;
  }

  cv::VideoCapture capture(videoPath.UTF8String);
  if (!capture.isOpened()) {
    if (error != nil) {
      *error = IOSDisplacementError(@"OpenCV가 영상을 열지 못했습니다.");
    }
    return nil;
  }

  int totalFrames = (int)capture.get(cv::CAP_PROP_FRAME_COUNT);
  int maxFrames = totalFrames > 0 ? std::min<int>(totalFrames, (int)IOSModelInputLength) : (int)IOSModelInputLength;
  if (progress != nil) {
    progress(@{@"processed": @0, @"total": @(maxFrames), @"progress": @0.0, @"detected": @0, @"missed": @0});
  }

  cv::Mat frame;
  std::vector<cv::Point2d> positions;
  double previousX = markerX;
  double previousY = markerY;
  bool isMarkerCoordinateInitialized = false;
  int detectedFrameCount = 0;
  int missedFrameCount = 0;
  int processedFrameCount = 0;
  int frameIndex = 0;

  while (frameIndex < maxFrames && capture.read(frame)) {
    frameIndex++;
    if (frame.empty()) {
      continue;
    }

    processedFrameCount++;
    int frameWidth = frame.cols;
    int frameHeight = frame.rows;
    int roiLeft = ClampInt((int)(roiX * frameWidth), 0, frameWidth - 1);
    int roiTop = ClampInt((int)(roiY * frameHeight), 0, frameHeight - 1);
    int roiRight = ClampInt((int)((roiX + roiWidth) * frameWidth), roiLeft + 1, frameWidth);
    int roiBottom = ClampInt((int)((roiY + roiHeight) * frameHeight), roiTop + 1, frameHeight);

    cv::Mat roiMat = frame(cv::Range(roiTop, roiBottom), cv::Range(roiLeft, roiRight));
    int roiPixelWidth = roiMat.cols;
    int roiPixelHeight = roiMat.rows;

    if (!isMarkerCoordinateInitialized) {
      if (markerXRatio >= 0.0 && markerYRatio >= 0.0) {
        previousX = std::max(0.0, std::min(markerXRatio * roiPixelWidth, (double)roiPixelWidth));
        previousY = std::max(0.0, std::min(markerYRatio * roiPixelHeight, (double)roiPixelHeight));
      }
      isMarkerCoordinateInitialized = true;
    }

    double effectiveTrackingBoxSize = trackingBoxSize;
    if (trackingBoxSizeRatio > 0.0) {
      effectiveTrackingBoxSize = trackingBoxSizeRatio * std::min(roiPixelWidth, roiPixelHeight);
    }
    double halfBox = std::max(3.0, effectiveTrackingBoxSize / 2.0);
    int searchLeft = ClampInt((int)(previousX - halfBox), 0, roiPixelWidth - 1);
    int searchTop = ClampInt((int)(previousY - halfBox), 0, roiPixelHeight - 1);
    int searchRight = ClampInt((int)(previousX + halfBox), searchLeft + 1, roiPixelWidth);
    int searchBottom = ClampInt((int)(previousY + halfBox), searchTop + 1, roiPixelHeight);
    cv::Mat searchMat = roiMat(cv::Range(searchTop, searchBottom), cv::Range(searchLeft, searchRight));

    bool foundInSearch = false;
    cv::Point2d searchCenter = DetectMarkerCenter(searchMat, hMin, hMax, sMin, sMax, vMin, vMax, &foundInSearch);

    bool found = foundInSearch;
    cv::Point2d roiCenter;
    if (foundInSearch) {
      roiCenter = cv::Point2d(searchLeft + searchCenter.x, searchTop + searchCenter.y);
    } else {
      roiCenter = DetectMarkerCenter(roiMat, hMin, hMax, sMin, sMax, vMin, vMax, &found);
    }

    if (found) {
      previousX = roiCenter.x;
      previousY = roiCenter.y;
      detectedFrameCount++;
      positions.push_back(cv::Point2d(previousX, previousY));
    } else {
      missedFrameCount++;
      if (!positions.empty()) {
        positions.push_back(cv::Point2d(previousX, previousY));
      }
    }

    if (progress != nil && (processedFrameCount % 10 == 0 || processedFrameCount == maxFrames)) {
      double ratio = maxFrames > 0 ? (double)processedFrameCount / (double)maxFrames : 0.0;
      progress(@{
        @"processed": @(processedFrameCount),
        @"total": @(maxFrames),
        @"progress": @(ratio),
        @"detected": @(detectedFrameCount),
        @"missed": @(missedFrameCount),
      });
    }
  }

  capture.release();

  if (detectedFrameCount == 0) {
    if (error != nil) {
      *error = IOSDisplacementError(@"마커가 한 프레임도 검출되지 않았습니다. HSV 범위, ROI, 마커 중심/박스 크기를 다시 확인해주세요.");
    }
    return nil;
  }
  if (positions.empty()) {
    if (error != nil) {
      *error = IOSDisplacementError(@"마커 변위를 계산하지 못했습니다.");
    }
    return nil;
  }

  double sumX = 0.0;
  double sumY = 0.0;
  for (const cv::Point2d &point : positions) {
    sumX += point.x;
    sumY += point.y;
  }
  double averageX = sumX / positions.size();
  double averageY = sumY / positions.size();

  std::vector<double> displacementX;
  std::vector<double> displacementZ;
  displacementX.reserve(positions.size());
  displacementZ.reserve(positions.size());
  for (const cv::Point2d &point : positions) {
    displacementX.push_back(point.x - averageX);
    displacementZ.push_back(point.y - averageY);
  }

  std::vector<double> modelInput = ResizeSeries(displacementZ, IOSModelInputLength);
  double zStdDev = StandardDeviation(displacementZ);

  NSString *csvDisplayName = nil;
  NSError *csvError = nil;
  NSString *csvPath = SaveCsv(displacementX, displacementZ, fps, &csvDisplayName, &csvError);
  if (csvPath == nil) {
    if (error != nil) {
      *error = csvError ?: IOSDisplacementError(@"CSV 파일을 저장하지 못했습니다.");
    }
    return nil;
  }

  if (progress != nil) {
    progress(@{
      @"processed": @(processedFrameCount),
      @"total": @(processedFrameCount),
      @"progress": @1.0,
      @"detected": @(detectedFrameCount),
      @"missed": @(missedFrameCount),
    });
  }

  return @{
    @"displacementZ": ArrayFromVector(modelInput),
    @"rawLength": @(processedFrameCount),
    @"detectedFrameCount": @(detectedFrameCount),
    @"missedFrameCount": @(missedFrameCount),
    @"zStdDev": @(zStdDev),
    @"csvUri": csvPath,
    @"csvDisplayName": csvDisplayName ?: csvPath,
  };
}

@end
