import Foundation
@testable import WordPressAuthenticator

final class MockWordPressComOAuthClientFacade: NSObject, WordPressComOAuthClientFacadeProtocol {
    struct AuthenticationResult {
        var userID: Int
        var nonceInfo: SocialLogin2FANonceInfo?
        var supportedAuthTypes: [String]
    }

    private(set) var oneTimeCodeRequestCount = 0
    private(set) var socialCodeRequestCount = 0
    private(set) var socialCodeRequestNonce: String?
    var authenticationResult: AuthenticationResult?

    required init(client: String, secret: String) {
        super.init()
    }

    func authenticate(
        username: String,
        password: String,
        multifactorCode: String?,
        success: @escaping (String?) -> Void,
        needsMultifactor: @escaping (Int, SocialLogin2FANonceInfo?, [String]) -> Void,
        failure: ((Error) -> Void)?
    ) {
        guard let authenticationResult else {
            return
        }
        needsMultifactor(authenticationResult.userID,
                         authenticationResult.nonceInfo,
                         authenticationResult.supportedAuthTypes)
    }

    func requestOneTimeCode(
        username: String,
        password: String,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void
    ) {
        oneTimeCodeRequestCount += 1
    }

    func requestSocial2FACode(
        userID: Int,
        nonce: String,
        success: @escaping (String) -> Void,
        failure: @escaping (Error, String?) -> Void
    ) {
        socialCodeRequestCount += 1
        socialCodeRequestNonce = nonce
    }

    func authenticate(
        socialIDToken: String,
        service: String,
        success: @escaping (String?) -> Void,
        needsMultifactor: @escaping (Int, SocialLogin2FANonceInfo) -> Void,
        existingUserNeedsConnection: @escaping (String) -> Void,
        failure: @escaping (Error) -> Void
    ) {}

    func authenticate(
        socialLoginUser userID: Int,
        authType: String,
        twoStepCode: String,
        twoStepNonce: String,
        success: @escaping (String?) -> Void,
        failure: @escaping (Error) -> Void
    ) {}

    func requestWebauthnChallenge(
        userID: Int64,
        twoStepNonce: String,
        success: @escaping (WebauthnChallengeInfo) -> Void,
        failure: @escaping (Error) -> Void
    ) {}

    func authenticateWebauthnSignature(
        userID: Int64,
        twoStepNonce: String,
        credentialID: Data,
        clientDataJson: Data,
        authenticatorData: Data,
        signature: Data,
        userHandle: Data,
        success: @escaping (String) -> Void,
        failure: @escaping (Error) -> Void
    ) {}
}
