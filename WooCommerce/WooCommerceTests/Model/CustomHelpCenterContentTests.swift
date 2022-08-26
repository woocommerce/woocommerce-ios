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
        let step: AuthenticatorAnalyticsTracker.Step = .magicLinkRequested
        let flow: AuthenticatorAnalyticsTracker.Flow = .prologue

        XCTAssertNil(CustomHelpCenterContent(step: step, flow: flow))
    }

    // MARK: Enter Store Address screen
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_store_address_screen() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .start
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithSiteAddress
        let helpContentURL = WooConstants.URLs.helpCenterForEnterStoreAddress.asURL()

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }

    // MARK: Enter WordPress.com email screen
    //
    func test_init_using_step_and_flow_returns_valid_instance_for_enter_WPCOM_email_address_screen() throws {
        // Given
        let step: AuthenticatorAnalyticsTracker.Step = .enterEmailAddress
        let flow: AuthenticatorAnalyticsTracker.Flow = .loginWithSiteAddress
        let helpContentURL = WooConstants.URLs.helpCenterForEnterWPCOMEmail.asURL()

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
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
        let helpContentURL = WooConstants.URLs.helpCenterForEnterStoreCredentials.asURL()

        // When
        let sut = try XCTUnwrap(CustomHelpCenterContent(step: step, flow: flow))

        // Then
        XCTAssertEqual(sut.url, helpContentURL)

        // Test the `trackingProperties` dictionary values
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.step.rawValue], step.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.flow.rawValue], flow.rawValue)
        XCTAssertEqual(sut.trackingProperties[CustomHelpCenterContent.Key.url.rawValue], helpContentURL.absoluteString)
    }
}
