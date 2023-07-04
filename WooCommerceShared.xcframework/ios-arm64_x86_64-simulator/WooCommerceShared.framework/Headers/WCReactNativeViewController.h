#import <UIKit/UIKit.h>
#import "WCRNAnalyticsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface WCReactNativeViewController : UIViewController

-(instancetype)initWithAnalyticsProvider:(id<WCRNAnalyticsProvider>) analyticsProvider
                                  blogID:(NSString *)blogId
                                apiToken: (NSString*) apiToken;

-(instancetype)initWithAnalyticsProvider:(id<WCRNAnalyticsProvider>) analyticsProvider
                                 siteUrl:(NSString *)siteUrl
                             appPassword: (NSString*) appPassword;

-(instancetype)initWithBundle:(NSURL *) url
            analyticsProvider:(id<WCRNAnalyticsProvider>) analyticsProvider
                       blogID:(NSString *)blogId
                     apiToken: (NSString*) apiToken;

-(instancetype)initWithBundle:(NSURL *) url
            analyticsProvider:(id<WCRNAnalyticsProvider>) analyticsProvider
                      siteUrl:(NSString *)siteUrl
                  appPassword: (NSString*) appPassword;
@end

NS_ASSUME_NONNULL_END
