#import <Foundation/Foundation.h>
#import <WordPressKit/WordPressComRESTAPIVersion.h>

@interface WordPressComRESTAPIVersionedPathBuilder: NSObject

+ (NSString *)pathForEndpoint:(NSString *)endpoint
                  withVersion:(WordPressComRESTAPIVersion)apiVersion
NS_SWIFT_NAME(path(forEndpoint:withVersion:));

@end
