#import <Foundation/Foundation.h>

@interface NSURL (IDN)
+ (NSString *)IDNEncodedHostname:(NSString *)aHostname;
+ (NSString *)IDNDecodedHostname:(NSString *)anIDNHostname;
+ (NSString *)IDNEncodedURL:(NSString *)aURL;
+ (NSString *)IDNDecodedURL:(NSString *)anIDNURL;
@end
