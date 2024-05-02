import XCTest
import Yosemite
import WordPressAuthenticator
import WordPressUI
@testable import WooCommerce

final class WrongAccountErrorViewModelTests: XCTestCase {

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, Expectations.findYourConnectedEmail)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: true,
                                                   siteCredentials: nil,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_right_bar_button_item() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   onJetpackSetupCompletion: { _, _ in })

        // Then
        XCTAssertEqual(viewModel.rightBarButtonItemTitle, Expectations.helpBarButtonItemTitle)
    }

    func test_viewmodel_provides_expected_title_for_log_out_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        let logoutButtonTitle = viewModel.logOutButtonTitle

        // Then
        XCTAssertEqual(logoutButtonTitle, Expectations.logOutButtonTitle)
    }

    func test_viewmodel_provides_expected_visibility_state_for_secondary_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        let visibility = viewModel.isSecondaryButtonHidden

        // Then
        XCTAssertTrue(visibility)
    }

    func test_viewModel_invokes_present_support_when_the_help_button_is_tapped() throws {
        // Given
        let mockAuthentication = MockAuthentication()
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   authentication: mockAuthentication,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        viewModel.didTapRightBarButtonItem(in: UIViewController())

        // Then
        XCTAssertTrue(mockAuthentication.presentSupportFromScreenInvoked)
    }

    func test_viewModel_sends_correct_screen_value_in_present_support_method() throws {
        // Given
        let mockAuthentication = MockAuthentication()
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   authentication: mockAuthentication,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        viewModel.didTapRightBarButtonItem(in: UIViewController())

        // Then
        XCTAssertEqual(mockAuthentication.presentSupportFromScreen, .wrongAccountError)
    }

    func test_fetchSiteInfo_is_triggered_if_credentials_are_not_present() {
        // Given

        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   authenticatorType: MockAuthenticator.self,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        viewModel.viewDidLoad(nil)

        // Then
        XCTAssertTrue(MockAuthenticator.fetchSiteInfoTriggered)
    }

    func test_error_view_is_tracked_with_selfhosted_site_if_credentials_are_present() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let credentials = WordPressOrgCredentials(username: "test", password: "pwd", xmlrpc: "http://test.com/xmlrpc.php", options: [:])
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: credentials,
                                                   analytics: analytics,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        viewModel.viewDidLoad(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "login_jetpack_connection_error_shown" }))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["is_selfhosted_site"] as? Bool, true)
    }

    func test_error_view_is_tracked_with_selfhosted_site_if_siteInfo_returns_selfhosted() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let siteInfo = WordPressComSiteInfo(remote: ["isWordPressDotCom": false])
        MockAuthenticator.setMockSiteInfo(siteInfo)

        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   authenticatorType: MockAuthenticator.self,
                                                   analytics: analytics,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        viewModel.viewDidLoad(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "login_jetpack_connection_error_shown" }))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["is_selfhosted_site"] as? Bool, true)
    }

    func test_error_view_is_tracked_without_selfhosted_site_if_siteInfo_returns_wpcom_site() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let siteInfo = WordPressComSiteInfo(remote: ["isWordPressDotCom": true])
        MockAuthenticator.setMockSiteInfo(siteInfo)

        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   authenticatorType: MockAuthenticator.self,
                                                   analytics: analytics,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        viewModel.viewDidLoad(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "login_jetpack_connection_error_shown" }))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["is_selfhosted_site"] as? Bool, false)
    }

    func test_primary_button_tap_is_tracked() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url,
                                                   showsConnectedStores: false,
                                                   siteCredentials: nil,
                                                   authenticatorType: MockAuthenticator.self,
                                                   analytics: analytics,
                                                   onJetpackSetupCompletion: { _, _ in })

        // When
        viewModel.didTapPrimaryButton(in: UIViewController())

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connect_button_tapped" }))
    }
}


private extension WrongAccountErrorViewModelTests {
    private enum Expectations {
        static let url = "https://woocommerce.com"
        static let image = UIImage.productErrorImage

        static let primaryButtonTitle = NSLocalizedString("Connect Jetpack",
                                                          comment: "Action button to handle connecting the logged-in account to a given site."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let secondaryButtonTitle = NSLocalizedString("See Connected Stores",
                                                            comment: "Action button linking to a list of connected stores."
                                                            + "Presented when logging in with a store address that does not match the account entered")

        static let logOutButtonTitle = NSLocalizedString("Log Out",
                                                          comment: "Action button triggering a Log Out."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let findYourConnectedEmail = NSLocalizedString("Find your connected email",
                                                     comment: "Button linking to webview explaining how to find your connected email"
                                                        + "Presented when logging in with a store address that does not match the account entered")

        static let helpBarButtonItemTitle = NSLocalizedString("Help",
                                                       comment: "Help button on account mismatch error screen.")
    }
}

private final class MockAuthenticator: Authenticator {
    enum AuthenticatorError: Error {
        case serviceError
    }

    private static var credentials: WordPressOrgCredentials?
    private static var siteInfo: WordPressComSiteInfo?

    static var fetchSiteInfoTriggered = false
    static var siteCredentialLoginTriggered = false

    static func setMockCredentials(_ credentials: WordPressOrgCredentials) {
        Self.credentials = credentials
    }

    static func setMockSiteInfo(_ siteInfo: WordPressComSiteInfo) {
        Self.siteInfo = siteInfo
    }

    static func showSiteCredentialLogin(from presenter: UIViewController, siteURL: String, onCompletion: @escaping (WordPressOrgCredentials) -> Void) {
        siteCredentialLoginTriggered = true
        guard let credentials = credentials else {
            return
        }
        onCompletion(credentials)
    }

    static func fetchSiteInfo(for siteURL: String, onCompletion: @escaping (Result<WordPressComSiteInfo, Error>) -> Void) {
        fetchSiteInfoTriggered = true
        guard let siteInfo = siteInfo else {
            return onCompletion(.failure(AuthenticatorError.serviceError))
        }
        onCompletion(.success(siteInfo))
    }
}
