import XCTest
@testable import WordPressAuthenticator
@testable import WooCommerce

final class CustomHelpCenterContentTests: XCTestCase {

    // MARK: CustomHelpCenterContent.Key
    //
    func test_step_key_has_correct_rawValue() {
        let sut = CustomHelpCenterContent.Key.step
        XCTAssertEqual(sut.rawValue, "source_step")
    }

    func test_flow_key_has_correct_rawValue() {
        let sut = CustomHelpCenterContent.Key.flow
        XCTAssertEqual(sut.rawValue, "source_flow")
    }

    func test_url_key_has_correct_rawValue() {
        let sut = CustomHelpCenterContent.Key.url
        XCTAssertEqual(sut.rawValue, "help_content_url")
    }

    // MARK: Invalid `Step` and `Flow`
    //
    func test_init_using_invalid_step_and_flow_returns_nil() {
        let step: AuthenticatorAnalyticsTracker.Step = .twoFactorAuthentication
        let flow: AuthenticatorAnalyticsTracker.Flow = .prologue

        XCTAssertNil(CustomHelpCenterContent(step: step, flow: flow))
    }

    // MARK: Enter Store Address screen
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_store_address_screen() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .start
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithSiteAddress

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForEnterStoreAddress.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Enter WordPress.com email screen from store address flow
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_WPCOM_email_address_screen() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .enterEmailAddress
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithSiteAddress

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForWPCOMEmailFromSiteAddressFlow.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Enter WordPress.com email screen from WPCOM email flow
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_WPCOM_email_address_screen_from_WPCOM_flow() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .enterEmailAddress
        let flow: AuthenticatorAnalyticsTracker.Flow = .wpCom

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForWPCOMEmailScreen.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Enter Store credentials screen (wp-admin creds)
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_store_creds_screen() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .usernamePassword
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithSiteAddress

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForEnterStoreCredentials.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Jetpack required error screen
    //
    func test_init_screen_returns_valid_instance_for_jetpack_required_error_screen() throws {
        // Given
        let step = "jetpack_not_connected"
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithPasswordWithMagicLinkEmphasis

        // When
        let sut = CustomHelpCenterContent(screen: .jetpackRequired, flow: flow)

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForJetpackRequiredError.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Store picker screen - `StorePickerViewController`
    //
    func test_init_screen_returns_valid_instance_for_store_picker_screen() throws {
        // Given
        let step = "site_list"
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithPasswordWithMagicLinkEmphasis

        // When
        let sut = CustomHelpCenterContent(screen: .storePicker, flow: flow)

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForStorePicker.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Enter WordPress.com password screen from normal WPCOM flow
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_WPCOM_password_screen() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .start
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithPassword

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForWPCOMPasswordScreen.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Enter WordPress.com password screen from magic link emphasis flow
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_WPCOM_password_screen_in_magic_link_emphasis_flow() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .start
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithPasswordWithMagicLinkEmphasis

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForWPCOMPasswordScreen.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Enter WordPress.com password screen for social login password challenge
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_WPCOM_password_screen_in_password_challenge_mode() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .passwordChallenge
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithGoogle

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForWPCOMPasswordScreen.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Open email screen after requesting magic link
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_open_email_screen() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .magicLinkRequested
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithSiteAddress

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForOpenEmail.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Open email screen after magic link has been auto requested
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_open_email_screen_after_magic_link_auto_request() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .magicLinkAutoRequested
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithSiteAddress

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForOpenEmail.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Account mismatch / Wrong WordPress.com account screen - `WrongAccountErrorViewModel`
    //
    func test_init_screen_returns_valid_instance_for_wrong_account_error_screen() throws {
        // Given
        let step = "wrong_wordpress_account"
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithPasswordWithMagicLinkEmphasis

        // When
        let sut = CustomHelpCenterContent(screen: .wrongAccountError, flow: flow)

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForWrongAccountError.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Not a WooCommerce site error screen presented using `NoWooErrorViewModel`
    //
    func test_init_screen_returns_valid_instance_for_not_a_woocommerce_site_error_screen() throws {
        // Given
        let step = "not_woo_store"
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithPasswordWithMagicLinkEmphasis

        // When
        let sut = CustomHelpCenterContent(screen: .noWooError, flow: flow)

        // Then
        let helpContentURL = WooConstants.URLs.helpCenterForNoWooError.asURL()
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }
}
