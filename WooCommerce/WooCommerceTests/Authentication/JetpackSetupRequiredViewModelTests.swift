import XCTest
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
    func test_jetpack_connection_error_is_tracked_when_the_view_is_loaded_when_connectionOnly_is_true() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let mockAuthentication = MockAuthentication()
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: true, authentication: mockAuthentication, analytics: analytics)

        // When
        viewModel.viewDidLoad(nil)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connection_error_shown" }))
    }

    func test_jetpack_required_error_is_tracked_when_the_view_is_loaded_when_connectionOnly_is_false() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let mockAuthentication = MockAuthentication()
        let viewModel = JetpackSetupRequiredViewModel(siteURL: testSiteURL, connectionOnly: false, authentication: mockAuthentication, analytics: analytics)

        // When
        viewModel.viewDidLoad(nil)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_required_screen_viewed" }))
    }
}
