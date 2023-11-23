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

- (void) requestWebauthnChallengeWithUserID: (NSInteger)userID
                               twoStepNonce:(NSString *)twoStepNonce
                                    success:(void (^)(WebauthnChallengeInfo *challengeData))success
                                    failure:(void (^)(NSError *error))failure {
    [self.client requestWebauthnChallengeWithUserID:userID twoStepNonce:twoStepNonce success:success failure:failure];
}

- (void) authenticateWebauthnSignatureWithUserID:(NSInteger)userID
                                    twoStepNonce:(NSString *)twoStepNonce
                                    credentialID:(NSData *)credentialID
                                  clientDataJson:(NSData *)clientDataJson
                               authenticatorData:(NSData *)authenticatorData
                                       signature:(NSData *)signature
                                      userHandle:(NSData *)userHandle
                                         success:(void (^)(NSString *authToken))success
                                         failure:(void (^)(NSError *error))failure {
    [self.client authenticateWebauthnSignatureWithUserID:userID
                                            twoStepNonce:twoStepNonce
                                            credentialID:credentialID
                                          clientDataJson:clientDataJson
                                       authenticatorData:authenticatorData
                                               signature:signature
                                              userHandle:userHandle
                                                 success:success
                                                 failure:failure];
}

@end
