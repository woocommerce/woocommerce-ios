#import "WordPressComOAuthClientFacade.h"
#import "WPAuthenticator-Swift.h"
@import WordPressKit;

@interface WordPressComOAuthClientFacade ()

@property (nonatomic, strong) WordPressComOAuthClient *client;

@end

@implementation WordPressComOAuthClientFacade

@synthesize client;

- (instancetype)initWithClient:(NSString *)client secret:(NSString *)secret
{
    NSParameterAssert(client);
    NSParameterAssert(secret);
    self = [super init];
    if (self) {
        self.client = [WordPressComOAuthClientFacade initializeOAuthClientWithClientID:client secret:secret];
    }

    return self;
}

- (instancetype)init {
    NSAssert(false, @"Please initializer WordPressComOAuthClientFacade with the ClientID and Secret!");
    return nil;
}

@end
