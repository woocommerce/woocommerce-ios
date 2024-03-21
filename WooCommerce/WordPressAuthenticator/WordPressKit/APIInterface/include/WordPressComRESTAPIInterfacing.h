@import Foundation;

@protocol WordPressComRESTAPIInterfacing

- (void)get:(NSString * _Nonnull)URLString
 parameters:(NSDictionary<NSString *, NSObject *> * _Nullable)parameters
    success:(void (^ _Nonnull)(id _Nonnull, NSHTTPURLResponse * _Nullable))success
    failure:(void (^ _Nonnull)(NSError * _Nonnull, NSHTTPURLResponse * _Nullable))failure;

- (void)post:(NSString * _Nonnull)URLString
  parameters:(NSDictionary<NSString *, NSObject *> * _Nullable)parameters
     success:(void (^ _Nonnull)(id _Nonnull, NSHTTPURLResponse * _Nullable))success
     failure:(void (^ _Nonnull)(NSError * _Nonnull, NSHTTPURLResponse * _Nullable))failure;

@end
