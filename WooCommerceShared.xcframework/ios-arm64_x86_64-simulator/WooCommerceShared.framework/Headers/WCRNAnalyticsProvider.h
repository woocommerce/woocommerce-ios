#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Analytics Provider Protocol. This will be implemented by the host app to delegate the track duties.
///
@protocol WCRNAnalyticsProvider
-(void)sendEvent:(NSString *)event;
@end

NS_ASSUME_NONNULL_END
