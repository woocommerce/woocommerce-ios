#import <Foundation/Foundation.h>

@class SocialLogin2FANonceInfo;
@class WebauthnChallengeInfo;
@protocol WordPressComOAuthClientFacadeProtocol

- (instancetype)initWithClient:(NSString *)client secret:(NSString *)secret;

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                needsMultiFactor:(void (^)(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo))needsMultifactor
                         failure:(void (^)(NSError *error))failure;

- (void)requestOneTimeCodeWithUsername:(NSString *)username
                              password:(NSString *)password
                               success:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure;

- (void)requestSocial2FACodeWithUserID:(NSInteger)userID
                                 nonce:(NSString *)nonce
                               success:(void (^)(NSString *newNonce))success
                               failure:(void (^)(NSError *error, NSString *newNonce))failure;

- (void)authenticateWithSocialIDToken:(NSString *)token
                              service:(NSString *)service
                              success:(void (^)(NSString *authToken))success
                     needsMultiFactor:(void (^)(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo))needsMultifactor
          existingUserNeedsConnection:(void (^)(NSString *email))existingUserNeedsConnection
                              failure:(void (^)(NSError *error))failure;

- (void)authenticateSocialLoginUser:(NSInteger)userID
                           authType:(NSString *)authType
                        twoStepCode:(NSString *)twoStepCode
                       twoStepNonce:(NSString *)twoStepNonce
                            success:(void (^)(NSString *authToken))success
                            failure:(void (^)(NSError *error))failure;

- (void) requestWebauthnChallengeWithUserID:(NSInteger)userID
                               twoStepNonce:(NSString *)twoStepNonce
                                    success:(void (^)(WebauthnChallengeInfo *challengeData))success
                                    failure:(void (^)(NSError *error))failure;

- (void) authenticateWebauthnSignatureWithUserID:(NSInteger)userID
                                    twoStepNonce:(NSString *)twoStepNonce
                                    credentialID:(NSData *)credentialID
                                  clientDataJson:(NSData *)clientDataJson
                               authenticatorData:(NSData *)authenticatorData
                                       signature:(NSData *)signature
                                      userHandle:(NSData *)userHandle
                                         success:(void (^)(NSString *authToken))success
                                         failure:(void (^)(NSError *error))failure;

@end
