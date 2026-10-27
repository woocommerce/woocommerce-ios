import Foundation
import Testing
@testable import WordPressAuthenticator

@MainActor
struct LoginFacadeTests {

    @Test
    func test_sign_in_when_password_response_has_400_two_factor_error_then_stores_methods_before_delegate() {
        // Given
        let methods = ["backup", "authenticator"]
        let client = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        client.authenticationResult = .init(userID: 0, nonceInfo: nil, supportedAuthTypes: methods)
        let delegate = LoginFacadeDelegateSpy()
        let loginFields = makeLoginFields()
        delegate.loginFieldsToInspect = loginFields
        let facade = makeLoginFacade(client: client, delegate: delegate)

        // When
        facade.signIn(with: loginFields)

        // Then
        #expect(delegate.needsMultifactorCodeWasCalled)
        #expect(delegate.supportedAuthTypesAtCallback == methods)
        #expect(loginFields.supportedAuthTypes == methods)
    }

    @Test
    func test_sign_in_when_password_response_has_200_challenge_then_stores_methods_and_nonce_before_delegate() {
        // Given
        let methods = ["backup", "webauthn"]
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        let client = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        client.authenticationResult = .init(userID: 1234, nonceInfo: nonceInfo, supportedAuthTypes: methods)
        let delegate = LoginFacadeDelegateSpy()
        let loginFields = makeLoginFields()
        delegate.loginFieldsToInspect = loginFields
        let facade = makeLoginFacade(client: client, delegate: delegate)

        // When
        facade.signIn(with: loginFields)

        // Then
        #expect(delegate.receivedUserID == 1234)
        #expect(delegate.receivedNonceInfo.map { $0 === nonceInfo } == true)
        #expect(delegate.supportedAuthTypesAtCallback == methods)
        #expect(loginFields.supportedAuthTypes == methods)
    }
}

private extension LoginFacadeTests {
    func makeLoginFields() -> LoginFields {
        let fields = LoginFields()
        fields.userIsDotCom = true
        fields.username = "test@example.com"
        fields.password = "password"
        return fields
    }

    func makeLoginFacade(client: MockWordPressComOAuthClientFacade, delegate: LoginFacadeDelegateSpy) -> LoginFacade {
        WordPressAuthenticator.initializeForTesting()
        let facade = LoginFacade(dotcomClientID: "Fake", dotcomSecret: "Fake", userAgent: "Fake")
        facade.wordpressComOAuthClientFacade = client
        facade.delegate = delegate
        return facade
    }
}

private final class LoginFacadeDelegateSpy: NSObject, LoginFacadeDelegate {
    private(set) var needsMultifactorCodeWasCalled = false
    private(set) var receivedUserID: Int?
    private(set) var receivedNonceInfo: SocialLogin2FANonceInfo?
    var loginFieldsToInspect: LoginFields?
    private(set) var supportedAuthTypesAtCallback: [String]?

    func needsMultifactorCode() {
        needsMultifactorCodeWasCalled = true
        supportedAuthTypesAtCallback = loginFieldsToInspect?.supportedAuthTypes
    }

    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        receivedUserID = userID
        receivedNonceInfo = nonceInfo
        supportedAuthTypesAtCallback = loginFieldsToInspect?.supportedAuthTypes
    }
}
