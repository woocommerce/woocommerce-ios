import XCTest
import Yosemite
import TestKit
@testable import WooCommerce

final class JetpackErrorViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil) { _ in }

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil) { _ in }

        // When
        let isVisible = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertFalse(isVisible)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil) { _ in }

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, Expectations.whatIsJetpack)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil) { _ in }

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil) { _ in }

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_right_bar_button_item() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil) { _ in }

        // Then
        XCTAssertEqual(viewModel.rightBarButtonItemTitle, Expectations.helpBarButtonItemTitle)
    }

    func test_viewModel_logs_an_event_when_viewDidLoad_is_triggered() throws {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil, analytics: analytics) { _ in }

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.viewDidLoad(nil)

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "login_jetpack_required_screen_viewed")
    }

    func test_viewModel_logs_an_event_when_install_jetpack_button_is_tapped() throws {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil, analytics: analytics) { _ in }

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.didTapPrimaryButton(in: nil)

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "login_jetpack_setup_button_tapped")
    }

    func test_viewModel_logs_an_event_when_the_what_is_jetpack_button_is_tapped() throws {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil, analytics: analytics) { _ in }

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.didTapAuxiliaryButton(in: nil)

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "login_what_is_jetpack_help_screen_viewed")
    }

    func test_viewModel_invokes_present_support_when_the_help_button_is_tapped() throws {
        // Given
        let mockAuthentication = MockAuthentication()
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil, authentication: mockAuthentication) { _ in }

        // When
        viewModel.didTapRightBarButtonItem(in: UIViewController())

        // Then
        XCTAssertTrue(mockAuthentication.presentSupportFromScreenInvoked)
    }

    func test_viewModel_sends_correct_screen_value_in_present_support_method() throws {
        // Given
        let mockAuthentication = MockAuthentication()
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, siteCredentials: nil, authentication: mockAuthentication) { _ in }

        // When
        viewModel.didTapRightBarButtonItem(in: UIViewController())

        // Then
        XCTAssertEqual(mockAuthentication.presentSupportFromScreen, .jetpackRequired)
    }
}


private extension JetpackErrorViewModelTests {
    private enum Expectations {
        static let url = "https://woocommerce.com"
        static let image = UIImage.loginNoJetpackError
        static let whatIsJetpack = NSLocalizedString("What is Jetpack?",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")
        static let primaryButtonTitle = NSLocalizedString("Set up Jetpack",
                                                          comment: "Action button for setting up Jetpack."
                                                          + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let helpBarButtonItemTitle = NSLocalizedString("Help",
                                                       comment: "Help button on Jetpack required error screen.")
    }
}
