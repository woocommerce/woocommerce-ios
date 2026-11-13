import Foundation
import WordPressAuthenticator

final class MockWordPressComOAuthClientFacade: NSObject, WordPressComOAuthClientFacadeProtocol {
    private(set) var oneTimeCodeRequestCount = 0

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
    ) {}

    func requestOneTimeCode(
        username: String,
        password: String,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void
    ) {
        oneTimeCodeRequestCount += 1
        success()
    }

    func requestSocial2FACode(
        userID: Int,
        nonce: String,
        success: @escaping (String) -> Void,
        failure: @escaping (Error, String?) -> Void
    ) {}

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
