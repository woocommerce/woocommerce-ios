#import <Foundation/Foundation.h>
#import <WordPressAuthenticator/PostServiceRemote.h>
#import <WordPressAuthenticator/ServiceRemoteWordPressXMLRPC.h>

@interface PostServiceRemoteXMLRPC : ServiceRemoteWordPressXMLRPC <PostServiceRemote>

+ (RemotePost *)remotePostFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary;

@end
