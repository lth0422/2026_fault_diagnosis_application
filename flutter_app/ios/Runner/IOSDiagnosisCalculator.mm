#import "IOSDiagnosisCalculator.h"

#import <algorithm>
#import <cmath>
#import <vector>

#import <ATen/ATen.h>
#import <torch/csrc/jit/mobile/import.h>
#import <torch/csrc/jit/mobile/module.h>

static const NSInteger IOSDiagnosisInputLength = 2048;
static NSString *const IOSDiagnosisModelName = @"Fwdcnn7";
static NSString *const IOSDiagnosisModelExtension = @"ptl";

static NSError *IOSDiagnosisError(NSString *message) {
  return [NSError errorWithDomain:@"IOSDiagnosisCalculator"
                             code:1
                         userInfo:@{NSLocalizedDescriptionKey: message}];
}

static NSArray<NSNumber *> *NSArrayFromFloatVector(const std::vector<float> &values) {
  NSMutableArray<NSNumber *> *array = [NSMutableArray arrayWithCapacity:values.size()];
  for (float value : values) {
    [array addObject:@(value)];
  }
  return array;
}

static std::vector<float> Softmax(const std::vector<float> &values) {
  if (values.empty()) {
    return {};
  }

  float maxValue = *std::max_element(values.begin(), values.end());
  std::vector<float> expValues;
  expValues.reserve(values.size());

  double sum = 0.0;
  for (float value : values) {
    double expValue = std::exp((double)value - (double)maxValue);
    expValues.push_back((float)expValue);
    sum += expValue;
  }

  if (sum == 0.0) {
    return std::vector<float>(values.size(), 0.0f);
  }

  std::vector<float> probabilities;
  probabilities.reserve(values.size());
  for (float value : expValues) {
    probabilities.push_back((float)((double)value / sum));
  }
  return probabilities;
}

@implementation IOSDiagnosisCalculator

+ (NSDictionary<NSString *, id> *)diagnoseWithDisplacementZ:(NSArray *)displacementZ
                                                      error:(NSError **)error {
  if (displacementZ.count != IOSDiagnosisInputLength) {
    if (error != nil) {
      *error = IOSDiagnosisError(
          [NSString stringWithFormat:@"모델 입력 길이는 %ld이어야 합니다. 현재: %lu",
                                     (long)IOSDiagnosisInputLength,
                                     (unsigned long)displacementZ.count]);
    }
    return nil;
  }

  NSString *modelPath = [[NSBundle mainBundle] pathForResource:IOSDiagnosisModelName
                                                        ofType:IOSDiagnosisModelExtension];
  if (modelPath.length == 0) {
    if (error != nil) {
      *error = IOSDiagnosisError(@"Fwdcnn7.ptl 모델 파일을 iOS 번들에서 찾지 못했습니다.");
    }
    return nil;
  }

  std::vector<float> inputData;
  inputData.reserve(IOSDiagnosisInputLength);
  for (id value in displacementZ) {
    if ([value respondsToSelector:@selector(floatValue)]) {
      inputData.push_back([value floatValue]);
    } else {
      inputData.push_back(0.0f);
    }
  }

  try {
    torch::jit::mobile::Module module = torch::jit::_load_for_mobile(modelPath.UTF8String);
    at::Tensor inputTensor = at::from_blob(
        inputData.data(),
        {1, 1, IOSDiagnosisInputLength},
        at::TensorOptions().dtype(at::kFloat));
    at::Tensor outputTensor = module.forward({inputTensor}).toTensor().contiguous();

    float *outputData = outputTensor.data_ptr<float>();
    int64_t outputCount = outputTensor.numel();
    std::vector<float> logits;
    logits.reserve((size_t)outputCount);
    for (int64_t index = 0; index < outputCount; index++) {
      logits.push_back(outputData[index]);
    }

    std::vector<float> probabilities = Softmax(logits);

    return @{
      @"classLabels": @[@"B", @"H", @"IR", @"OR"],
      @"probabilities": NSArrayFromFloatVector(probabilities),
      @"logits": NSArrayFromFloatVector(logits),
      @"modelName": @"Fwdcnn7.ptl",
    };
  } catch (const std::exception &exception) {
    if (error != nil) {
      *error = IOSDiagnosisError(
          [NSString stringWithFormat:@"iOS PyTorch Lite 모델 추론 실패: %s", exception.what()]);
    }
    return nil;
  } catch (...) {
    if (error != nil) {
      *error = IOSDiagnosisError(@"iOS PyTorch Lite 모델 추론 중 알 수 없는 오류가 발생했습니다.");
    }
    return nil;
  }
}

@end
