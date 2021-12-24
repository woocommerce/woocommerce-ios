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
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url)

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url)

        // When
        let isVisible = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertFalse(isVisible)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url)

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, Expectations.whatIsJetpack)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url)

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url)

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }

    func test_viewModel_logs_an_event_when_viewDidLoad_is_triggered() throws {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, analytics: analytics)

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.viewDidLoad()

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "login_jetpack_required_screen_viewed")
    }

    func test_viewModel_logs_an_event_when_see_instructions_button_is_tapped() throws {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, analytics: analytics)

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.didTapPrimaryButton(in: nil)

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "login_jetpack_required_view_instructions_button_tapped")
    }

    func test_viewModel_logs_an_event_when_the_what_is_jetpack_button_is_tapped() throws {
        // Given
        let viewModel = JetpackErrorViewModel(siteURL: Expectations.url, analytics: analytics)

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.didTapAuxiliaryButton(in: nil)

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "login_what_is_jetpack_help_screen_viewed")
    }
}


private extension JetpackErrorViewModelTests {
    private enum Expectations {
        static let url = "https://woocommerce.com"
        static let image = UIImage.loginNoJetpackError
        static let whatIsJetpack = NSLocalizedString("What is Jetpack?",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")
        static let primaryButtonTitle = NSLocalizedString("See Instructions",
                                                          comment: "Action button linking to instructions for installing Jetpack."
                                                          + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")
    }
}
