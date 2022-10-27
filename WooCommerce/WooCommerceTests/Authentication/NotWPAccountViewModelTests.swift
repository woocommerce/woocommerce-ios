import XCTest
import WordPressAuthenticator
@testable import WooCommerce

final class NotWPAccountViewModelTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        initializeAuthenticator()
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
        let expectation = NSAttributedString(string: Expectations.errorMessage)

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

    func test_viewmodel_provides_expected_title_for_primary_button_when_simplified_login_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSimplifiedLoginFlowI1Enabled: false)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                               featureFlagService: featureFlagService)

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.loginWithSiteAddressTitle)
    }

    func test_viewmodel_provides_expected_title_for_primary_button_when_simplified_login_feature_flag_is_on() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSimplifiedLoginFlowI1Enabled: true)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                               featureFlagService: featureFlagService)
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

    func test_primary_button_title_is_login_with_site_address_for_invalidWPComEmail_from_wpCom_error_when_simplified_login_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSimplifiedLoginFlowI1Enabled: false)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              featureFlagService: featureFlagService)
        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.loginWithSiteAddressTitle)
    }

    func test_primary_button_title_is_login_with_site_address_for_invalidWPComEmail_from_wpCom_error_when_simplified_login_feature_flag_is_on() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSimplifiedLoginFlowI1Enabled: true)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              featureFlagService: featureFlagService)
        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.createAnAccountTitle)
    }

    // MARK: - `isSecondaryButtonHidden`

    func test_secondary_button_is_hidden_for_invalidWPComEmail_from_site_address_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpComSiteAddress))

        // When
        let isPrimaryButtonHidden = viewModel.isSecondaryButtonHidden

        // Then
        XCTAssertTrue(isPrimaryButtonHidden)
    }

    func test_secondary_button_is_not_hidden_for_invalidWPComEmail_from_wpCom_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom))

        // When
        let isPrimaryButtonHidden = viewModel.isSecondaryButtonHidden

        // Then
        XCTAssertFalse(isPrimaryButtonHidden)
    }

    // MARK: - `secondaryButtonTitle`

    func test_viewmodel_provides_expected_title_for_secondary_button_when_simplified_login_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSimplifiedLoginFlowI1Enabled: false)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                               featureFlagService: featureFlagService)

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.restartLoginTitle)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button_when_simplified_login_feature_flag_is_on() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSimplifiedLoginFlowI1Enabled: true)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                               featureFlagService: featureFlagService)
        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.tryAnotherAddressTitle)
    }

    func test_tapping_auxiliary_button_tracks_what__is_wordpress_com_event() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let featureFlagService = MockFeatureFlagService(isSimplifiedLoginFlowI1Enabled: true)
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom),
                                              analytics: analytics,
                                              featureFlagService: featureFlagService)

        // When
        viewModel.didTapAuxiliaryButton(in: nil)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "what_is_wordpress_com_on_invalid_email_screen" }))
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


// MARK: - WordPressAuthenticator Initialization

private extension NotWPAccountViewModelTests {
    /// Initialize `WordPressAuthenticator` with dummy configuration.
    ///
    /// For some reason, the tests in this class fail when the `.view` is loaded because
    /// `NUXButton` instances used within `ULErrorViewController` seem to _phone home_ and access
    /// the `WordPressAuthenticator` instance. And since the `WordPressAuthenticator` instance
    /// was not initialized, I get a unit test fatal error:
    ///
    /// ```
    /// WordPressAuthenticator wasn't initialized
    /// ```
    ///
    /// Initializing with dummy data seems to work.
    ///
    /// There is no known way to tear down this instance. Once initialized, it's initialized. And
    /// I don't believe we use `WordPressAuthenticator` anywhere else. So hopefully this will not
    /// bleed into the other unit tests. ¯\(°_o)/¯
    func initializeAuthenticator() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: "",
                                                                wpcomSecret: "",
                                                                wpcomScheme: "",
                                                                wpcomTermsOfServiceURL: "",
                                                                wpcomAPIBaseURL: "",
                                                                googleLoginClientId: "",
                                                                googleLoginServerClientId: "",
                                                                googleLoginScheme: "",
                                                                userAgent: "",
                                                                showLoginOptions: true,
                                                                enableSignUp: false,
                                                                enableSignInWithApple: false,
                                                                enableSignupWithGoogle: false,
                                                                enableUnifiedAuth: true,
                                                                continueWithSiteAddressFirst: true)

        let style = WordPressAuthenticatorStyle(primaryNormalBackgroundColor: .red,
                                                primaryNormalBorderColor: .red,
                                                primaryHighlightBackgroundColor: .red,
                                                primaryHighlightBorderColor: .red,
                                                secondaryNormalBackgroundColor: .red,
                                                secondaryNormalBorderColor: .red,
                                                secondaryHighlightBackgroundColor: .red,
                                                secondaryHighlightBorderColor: .red,
                                                disabledBackgroundColor: .red,
                                                disabledBorderColor: .red,
                                                primaryTitleColor: .primaryButtonTitle,
                                                secondaryTitleColor: .red,
                                                disabledTitleColor: .red,
                                                disabledButtonActivityIndicatorColor: .red,
                                                textButtonColor: .red,
                                                textButtonHighlightColor: .red,
                                                instructionColor: .red,
                                                subheadlineColor: .red,
                                                placeholderColor: .red,
                                                viewControllerBackgroundColor: .red,
                                                textFieldBackgroundColor: .red,
                                                buttonViewBackgroundColor: .red,
                                                buttonViewTopShadowImage: nil,
                                                navBarImage: UIImage(),
                                                navBarBadgeColor: .red,
                                                navBarBackgroundColor: .red,
                                                prologueTopContainerChildViewController: nil,
                                                statusBarStyle: .default)

        let displayStrings = WordPressAuthenticatorDisplayStrings(emailLoginInstructions: "",
                                                                  getStartedInstructions: "",
                                                                  jetpackLoginInstructions: "",
                                                                  siteLoginInstructions: "",
                                                                  usernamePasswordInstructions: "",
                                                                  continueWithWPButtonTitle: "",
                                                                  enterYourSiteAddressButtonTitle: "",
                                                                  findSiteButtonTitle: "",
                                                                  signupTermsOfService: "",
                                                                  getStartedTitle: "")

        let unifiedStyle = WordPressAuthenticatorUnifiedStyle(borderColor: .red,
                                                              errorColor: .red,
                                                              textColor: .red,
                                                              textSubtleColor: .red,
                                                              textButtonColor: .red,
                                                              textButtonHighlightColor: .red,
                                                              viewControllerBackgroundColor: .red,
                                                              prologueButtonsBackgroundColor: .red,
                                                              prologueViewBackgroundColor: .red,
                                                              navBarBackgroundColor: .red,
                                                              navButtonTextColor: .red,
                                                              navTitleTextColor: .red)

        let displayImages = WordPressAuthenticatorDisplayImages(
            magicLink: UIImage(),
            siteAddressModalPlaceholder: UIImage()
        )

        WordPressAuthenticator.initialize(configuration: configuration,
                                          style: style,
                                          unifiedStyle: unifiedStyle,
                                          displayImages: displayImages,
                                          displayStrings: displayStrings)
    }
}
