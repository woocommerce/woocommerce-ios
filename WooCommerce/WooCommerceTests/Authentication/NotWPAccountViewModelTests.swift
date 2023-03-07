import XCTest
import WordPressAuthenticator
@testable import WooCommerce
import TestKit

final class NotWPAccountViewModelTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        // There is no known tear down for the Authenticator.
        super.tearDown()
    }

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = NotWPAccountViewModel()

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_error_message() {
        // Given
        let viewModel = NotWPAccountViewModel()
        let expectation = NSAttributedString(string: Expectations.errorMessage, attributes: [.font: UIFont.title3SemiBold])

        // When
        let errorMessage = viewModel.text

        // Then
        XCTAssertEqual(errorMessage, expectation)
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = NotWPAccountViewModel()

        // When
        let isHidden = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertFalse(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = NotWPAccountViewModel()

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, AuthenticationConstants.whatIsWPComLinkTitle)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom))
        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.createAnAccountTitle)
    }

    // MARK: - `primaryButtonTitle`

    func test_primary_button_title_is_restart_login_for_invalidWPComEmail_from_site_address_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpComSiteAddress))

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.restartLoginTitle)
    }

    func test_primary_button_title_is_create_an_account_for_invalidWPComEmail_from_wpCom_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom))
        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.createAnAccountTitle)
    }

    // MARK: - `isPrimaryButtonHidden`

    func test_primary_button_is_not_hidden_for_invalidWPComEmail_from_site_address_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpComSiteAddress))

        // Then
        XCTAssertFalse(viewModel.isPrimaryButtonHidden)
    }

    func test_primary_button_is_not_hidden_for_invalidWPComEmail_from_wpCom_error_when_store_creation_is_on() {
        // Given
        let featureFlagService = MockFeatureFlagService(isStoreCreationMVPEnabled: true)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              featureFlagService: featureFlagService)
        // Then
        XCTAssertFalse(viewModel.isPrimaryButtonHidden)
    }

    func test_primary_button_is_hidden_for_invalidWPComEmail_from_wpCom_error_when_store_creation_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isStoreCreationMVPEnabled: false)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              featureFlagService: featureFlagService)
        // Then
        XCTAssertTrue(viewModel.isPrimaryButtonHidden)
    }

    // MARK: - `isSecondaryButtonHidden`

    func test_secondary_button_is_hidden_for_invalidWPComEmail_from_site_address_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpComSiteAddress))

        // Then
        XCTAssertTrue(viewModel.isSecondaryButtonHidden)
    }

    func test_secondary_button_is_not_hidden_for_invalidWPComEmail_from_wpCom_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom))

        // Then
        XCTAssertFalse(viewModel.isSecondaryButtonHidden)
    }

    // MARK: - `secondaryButtonTitle`

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom))
        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.tryAnotherAddressTitle)
    }

    // MARK: - Analytics

    func test_viewModel_logs_an_event_when_viewDidLoad_is_triggered() throws {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              analytics: analytics)

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.viewDidLoad(nil)

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "login_invalid_email_screen_viewed")
    }

    func test_tapping_auxiliary_button_tracks_what__is_wordpress_com_event() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              analytics: analytics)

        // When
        viewModel.didTapAuxiliaryButton(in: nil)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "what_is_wordpress_com_on_invalid_email_screen" }))
    }

    func test_tapping_primary_button_tracks_create_account_event() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              analytics: analytics)

        // When
        viewModel.didTapPrimaryButton(in: nil)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "create_account_on_invalid_email_screen" }))
    }
}


private extension NotWPAccountViewModelTests {
    private enum Expectations {
        static let image = UIImage.loginNoWordPressError
        static let errorMessage = NSLocalizedString("Your email isn't used with a WordPress.com account",
                                                    comment: "Message explaining that an email is not associated with a WordPress.com account. "
                                                    + "Presented when logging in with an email address that is not a WordPress.com account")

        static let loginWithSiteAddressTitle = NSLocalizedString("Log in with your store address",
                                                                 comment: "Action button linking to instructions for enter another store."
                                                                 + "Presented when logging in with an email address that is not a WordPress.com account")

        static let restartLoginTitle = NSLocalizedString("Log in with another account",
                                                         comment: "Action button that will restart the login flow."
                                                         + "Presented when logging in with an email address that does not match a WordPress.com account")

        static let createAnAccountTitle = NSLocalizedString("Create An Account",
                                                       comment: "Action button linking to create WooCommerce store flow."
                                                       + "Presented when logging in with an email address that is not a WordPress.com account")

        static let tryAnotherAddressTitle = NSLocalizedString("Try Another Address",
                                                         comment: "Action button that will restart the login flow."
                                                         + "Presented when logging in with an email address that does not match a WordPress.com account")
    }
}

private extension NotWPAccountViewModel {
    convenience init() {
        self.init(error: SignInError.invalidWPComEmail(source: .wpCom))
    }
}
