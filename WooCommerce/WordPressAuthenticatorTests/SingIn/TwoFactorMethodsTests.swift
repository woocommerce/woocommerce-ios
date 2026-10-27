import Testing
@testable import WordPressAuthenticator

struct TwoFactorMethodsTests {

    @Test
    func test_methods_when_list_is_empty_or_unknown_then_hides_text_option() {
        // Given
        let noList = TwoFactorMethods(supportedAuthTypes: [])
        let unknownList = TwoFactorMethods(supportedAuthTypes: ["push"])

        // When / Then
        #expect(!noList.canTextCode)
        #expect(!unknownList.canTextCode)
        #expect(!noList.startsWithSecurityKey)
        #expect(noList.instructions(hasRequestedTextCode: false, isBackupCodeRequested: false) == nil)
    }

    @Test
    func test_instructions_when_authenticator_is_available_then_keeps_authenticator_copy() {
        // Given
        let methods = TwoFactorMethods(supportedAuthTypes: ["authenticator", "sms", "webauthn"])

        // When / Then
        #expect(methods.instructions(hasRequestedTextCode: false, isBackupCodeRequested: false) == nil)
        #expect(methods.canTextCode)
        #expect(!methods.startsWithSecurityKey)
    }

    @Test
    func test_instructions_when_text_code_is_selected_then_shows_text_message_copy() {
        // Given
        let methods = TwoFactorMethods(supportedAuthTypes: ["sms"])

        // When / Then
        #expect(methods.instructions(hasRequestedTextCode: false, isBackupCodeRequested: false) ==
                "We sent a text message. Enter the verification code from the message.")
        #expect(methods.instructions(hasRequestedTextCode: true, isBackupCodeRequested: false) ==
                "We sent a text message. Enter the verification code from the message.")
    }

    @Test
    func test_instructions_when_email_is_the_only_method_then_shows_email_copy() {
        // Given
        let methods = TwoFactorMethods(supportedAuthTypes: ["email"])

        // When / Then
        #expect(!methods.canTextCode)
        #expect(methods.instructions(hasRequestedTextCode: false, isBackupCodeRequested: false) ==
                "Check your email for a verification code from WordPress.com, then enter it to continue.")
    }

    @Test
    func test_instructions_when_security_key_is_first_then_backup_code_switches_to_backup_copy() {
        // Given
        let methods = TwoFactorMethods(supportedAuthTypes: ["webauthn", "backup"])

        // When / Then
        #expect(methods.startsWithSecurityKey)
        #expect(methods.canUseBackupCode)
        #expect(!methods.canTextCode)
        #expect(methods.instructions(hasRequestedTextCode: false, isBackupCodeRequested: false) ==
                "Please provide your security key to continue.")
        #expect(methods.instructions(hasRequestedTextCode: false, isBackupCodeRequested: true) ==
                "Enter a backup code to continue.")
    }

    @Test
    func test_instructions_when_backup_code_is_requested_after_a_text_code_then_shows_backup_copy() {
        // Given
        let methods = TwoFactorMethods(supportedAuthTypes: ["backup", "authenticator", "sms"])

        // When / Then
        #expect(methods.instructions(hasRequestedTextCode: true, isBackupCodeRequested: true) ==
                "Enter a backup code to continue.")
    }

    @Test
    func test_textCodeButtonTitle_when_text_message_instructions_show_then_offers_to_resend() {
        // Given
        let smsFirst = TwoFactorMethods(supportedAuthTypes: ["backup", "sms"])
        let authenticatorFirst = TwoFactorMethods(supportedAuthTypes: ["backup", "authenticator", "sms"])
        let title = "Text me a code"

        // When / Then
        #expect(smsFirst.textCodeButtonTitle(defaultTitle: title, hasRequestedTextCode: false, isBackupCodeRequested: false) == "Resend code via SMS")
        #expect(authenticatorFirst.textCodeButtonTitle(defaultTitle: title, hasRequestedTextCode: false, isBackupCodeRequested: false) == title)
        #expect(authenticatorFirst.textCodeButtonTitle(defaultTitle: title, hasRequestedTextCode: true, isBackupCodeRequested: false) == "Resend code via SMS")
        #expect(smsFirst.textCodeButtonTitle(defaultTitle: title, hasRequestedTextCode: true, isBackupCodeRequested: true) == title)
    }

    @Test
    func test_methods_when_security_key_is_the_only_method_then_offers_no_backup_code() {
        // Given
        let methods = TwoFactorMethods(supportedAuthTypes: ["webauthn"])

        // When / Then
        #expect(methods.startsWithSecurityKey)
        #expect(!methods.canUseBackupCode)
    }

    @Test
    func test_methods_when_security_key_comes_with_email_code_then_starts_with_email_code() {
        // Given
        let methods = TwoFactorMethods(supportedAuthTypes: ["email", "webauthn"])

        // When / Then
        #expect(!methods.startsWithSecurityKey)
        #expect(methods.instructions(hasRequestedTextCode: false, isBackupCodeRequested: false) ==
                "Check your email for a verification code from WordPress.com, then enter it to continue.")
    }

    @Test
    func test_canTextCode_when_the_account_list_is_empty_then_follows_the_challenge_list() {
        // Given
        let smsChallenge = TwoFactorMethods(supportedAuthTypes: [], challengeAuthTypes: ["authenticator", "sms"])
        let otherChallenge = TwoFactorMethods(supportedAuthTypes: [], challengeAuthTypes: ["authenticator", "backup"])
        let accountList = TwoFactorMethods(supportedAuthTypes: ["authenticator"], challengeAuthTypes: ["sms"])

        // When / Then
        #expect(smsChallenge.canTextCode)
        #expect(!otherChallenge.canTextCode)
        #expect(!accountList.canTextCode)
        #expect(smsChallenge.instructions(hasRequestedTextCode: false, isBackupCodeRequested: false) == nil)
    }
}
