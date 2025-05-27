#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WPMediaPickerAlertHelper : NSObject

+ (nonnull UIAlertController *)buildAlertControllerWithError:(NSError * _Nullable)error
                                             okActionHandler:(void (^ __nullable)(UIAlertAction * _Nullable action))handler;

@end
