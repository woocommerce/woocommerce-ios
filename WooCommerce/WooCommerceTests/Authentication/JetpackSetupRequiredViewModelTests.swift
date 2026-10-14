import XCTest
@testable import WordPressAuthenticator
import WordPressShared
@testable import WooCommerce

final class JetpackSetupRequiredViewModelTests: XCTestCase {

    private let testSiteURL = "https://test.com"

    func test_view_model_provides_expected_image_if_connectionOnly_is_false() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: false)

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, .jetpackSetupImage)
    }

    func test_view_model_provides_expected_image_if_connectionOnly_is_true() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, .jetpackConnectionImage)
    }

    func test_view_model_provides_expected_title() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: false)

        // When
        let title = viewModel.title

        // Then
        XCTAssertEqual(title, JetpackSetupRequiredViewModel.Localization.title)
    }

    func test_view_model_provides_expected_error_message_when_connectionOnly_is_false() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: false)
        let expectedText = JetpackSetupRequiredViewModel.Localization.setupErrorMessage
            .replacingOccurrences(of: "%@", with: testSiteURL.trimHTTPScheme()) +
            "\n\n" +
            JetpackSetupRequiredViewModel.Localization.setupSubtitle

        // When
        let text = viewModel.text.string

        // Then
        XCTAssertEqual(text, expectedText)
    }

    func test_view_model_provides_expected_error_message_when_connectionOnly_is_true() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)
        let expectedText = JetpackSetupRequiredViewModel.Localization.connectionErrorMessage
            .replacingOccurrences(of: "%@", with: testSiteURL.trimHTTPScheme()) +
            "\n\n" +
            JetpackSetupRequiredViewModel.Localization.setupSubtitle

        // When
        let text = viewModel.text.string

        // Then
        XCTAssertEqual(text, expectedText)
    }

    func test_view_model_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)

        // When
        let isHidden = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertTrue(isHidden)
    }

    func test_view_model_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)

        // When
        let title = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertTrue(title.isEmpty)
    }

    func test_view_model_provides_expected_title_for_primary_button_when_connectionOnly_is_false() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: false)

        // When
        let title = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(title, JetpackSetupRequiredViewModel.Localization.installJetpack)
    }

    func test_view_model_provides_expected_title_for_primary_button_when_connectionOnly_is_true() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)

        // When
        let title = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(title, JetpackSetupRequiredViewModel.Localization.connectJetpack)
    }

    func test_view_model_provides_expected_visibility_for_secondary_button() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)

        // When
        let isHidden = viewModel.isSecondaryButtonHidden

        // Then
        XCTAssertTrue(isHidden)
    }

    func test_view_model_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)

        // When
        let title = viewModel.secondaryButtonTitle

        // Then
        XCTAssertTrue(title.isEmpty)
    }

    func test_view_model_provides_expected_title_for_right_bar_button_item() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)

        // When
        let title = viewModel.rightBarButtonItemTitle

        // Then
        XCTAssertEqual(title, JetpackSetupRequiredViewModel.Localization.helpBarButtonItemTitle)
    }

    func test_view_model_provides_expected_terms_label_text() {
        // Given
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true)
        let expectedText = String(format: JetpackSetupRequiredViewModel.Localization.termsContent,
                                  JetpackSetupRequiredViewModel.Localization.termsOfService,
                                  JetpackSetupRequiredViewModel.Localization.shareDetails)

        // When
        let text = viewModel.termsLabelText?.string

        // Then
        XCTAssertEqual(text, expectedText)
    }

    func test_viewModel_invokes_present_support_when_the_help_button_is_tapped() throws {
        // Given
        let mockAuthentication = MockAuthentication()
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: false, authentication: mockAuthentication)

        // When
        viewModel.didTapRightBarButtonItem(in: UIViewController())

        // Then
        XCTAssertTrue(mockAuthentication.presentSupportFromScreenInvoked)
    }

    // MARK: - Analytics
    func test_viewDidLoad_tracks_the_legacy_screen_viewed_event_when_jetpack_is_not_installed() {
        // Given Jetpack is not installed, the `connectionOnly == false` branch
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL,
                                                      connectionOnly: false,
                                                      reportsLoginStep: false,
                                                      authentication: MockAuthentication(),
                                                      analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        viewModel.viewDidLoad(nil)

        // Then the legacy event is still tracked, which is what covers the out-of-login case
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("login_jetpack_required_screen_viewed"))
    }

    func test_viewDidLoad_reports_no_login_step_outside_a_login_journey() {
        // Given the screen was reached from an in-app store switch
        var events: [AnalyticsEvent] = []
        let analyticsProvider = MockAnalyticsProvider()
        let tracker = AuthenticatorAnalyticsTracker(enabled: true, track: { events.append($0) })
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL,
                                                      connectionOnly: true,
                                                      reportsLoginStep: false,
                                                      authentication: MockAuthentication(),
                                                      analytics: WooAnalytics(analyticsProvider: analyticsProvider),
                                                      tracker: tracker)

        // When
        viewModel.viewDidLoad(nil)

        // Then no login step, but the screen is still counted by the legacy event
        XCTAssertTrue(events.isEmpty)
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("login_jetpack_connection_error_shown"))
    }

    func test_viewDidLoad_reports_jetpack_not_connected_when_connectionOnly_is_true() {
        // Given
        var events: [AnalyticsEvent] = []
        let tracker = AuthenticatorAnalyticsTracker(enabled: true, track: { events.append($0) })
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL,
                                                      connectionOnly: true,
                                                      reportsLoginStep: true,
                                                      authentication: MockAuthentication(),
                                                      tracker: tracker)

        // When
        viewModel.viewDidLoad(nil)

        // Then
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.properties["step"], "jetpack_not_connected")
        XCTAssertEqual(events.first?.properties["url"], "test.com")
    }

    func test_viewDidLoad_reports_jetpack_not_installed_when_connectionOnly_is_false() {
        // Given
        var events: [AnalyticsEvent] = []
        let tracker = AuthenticatorAnalyticsTracker(enabled: true, track: { events.append($0) })
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL,
                                                      connectionOnly: false,
                                                      reportsLoginStep: true,
                                                      authentication: MockAuthentication(),
                                                      tracker: tracker)

        // When
        viewModel.viewDidLoad(nil)

        // Then
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.properties["step"], "jetpack_not_installed")
        XCTAssertEqual(events.first?.properties["url"], "test.com")
    }
}
