import Testing
@testable import WordPressAuthenticator

struct SocialLogin2FANonceInfoTests {

    @Test(arguments: ["123456", "1234567", "12345678"])
    func test_authTypeAndNonce_when_nonce_is_missing_then_leaves_it_empty(code: String) {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()

        // When
        let firstNonce = nonceInfo.authTypeAndNonce(for: code).1
        let secondNonce = nonceInfo.authTypeAndNonce(for: code).1

        // Then
        #expect(firstNonce.isEmpty)
        #expect(secondNonce.isEmpty)
    }

    @Test
    func test_authTypeAndNonce_when_nonce_is_set_then_lets_updateNonce_replace_it() {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceSMS = "nonce"

        // When
        let firstResult = nonceInfo.authTypeAndNonce(for: "1234567")
        nonceInfo.updateNonce(with: "new")
        let secondResult = nonceInfo.authTypeAndNonce(for: "1234567")

        // Then
        #expect(firstResult.0 == "sms")
        #expect(firstResult.1 == "nonce")
        #expect(secondResult.1 == "new")
    }
}
