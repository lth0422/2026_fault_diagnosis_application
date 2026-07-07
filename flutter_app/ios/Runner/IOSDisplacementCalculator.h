#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^IOSDisplacementProgressBlock)(NSDictionary<NSString *, id> *progress);

@interface IOSDisplacementCalculator : NSObject

+ (nullable NSDictionary<NSString *, id> *)computeWithArguments:(NSDictionary<NSString *, id> *)arguments
                                                       progress:(nullable IOSDisplacementProgressBlock)progress
                                                          error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
