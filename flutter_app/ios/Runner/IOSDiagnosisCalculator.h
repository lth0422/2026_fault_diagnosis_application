#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IOSDiagnosisCalculator : NSObject

+ (nullable NSDictionary<NSString *, id> *)diagnoseWithDisplacementZ:(NSArray *)displacementZ
                                                               error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
