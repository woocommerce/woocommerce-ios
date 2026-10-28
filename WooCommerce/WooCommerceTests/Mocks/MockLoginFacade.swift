import WordPressAuthenticator

final class MockLoginFacade: LoginFacade {
    private(set) var signedInLoginFields: LoginFields?
    private(set) var signInCallCount = 0
    private(set) var nonceAuthenticationCallCount = 0

    override func signIn(with loginFields: LoginFields) {
        signedInLoginFields = loginFields
        signInCallCount += 1
    }

    override func loginToWordPressDotCom(
        withUser userID: Int,
        authType: String,
        twoStepCode: String,
        twoStepNonce: String
    ) {
        nonceAuthenticationCallCount += 1
    }
}
