import XCTest
import WordPressAuthenticator
@testable import WooCommerce

final class ULErrorViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        initializeAuthenticator()
    }

    override func tearDown() {
        // There is no known tear down for the Authenticator. So this method intentionally does
        // nothing.
        super.tearDown()
    }

    func test_viewcontroller_presents_image_provided_by_viewmodel() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let image = viewController.getImageView().image

        // Then
        XCTAssertEqual(image, viewModel.image)
    }

    func test_viewcontroller_presents_text_provided_by_viewmodel() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let text = viewController.getLabel().attributedText

        // Then
        XCTAssertEqual(text, viewModel.text)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_auxbutton() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let auxiliaryButtonTitle = viewController.getAuxiliaryButton().title(for: .normal)

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, viewModel.auxiliaryButtonTitle)
    }

    func test_viewcontroller_assigns_visibility_provided_by_viewmodel_to_auxbutton() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let auxiliaryButtonHidden = viewController.getAuxiliaryButton().isHidden

        // Then
        XCTAssertEqual(auxiliaryButtonHidden, viewModel.isAuxiliaryButtonHidden)
    }

    func test_viewcontroller_hits_viewmodel_when_auxbutton_is_tapped() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)

        let auxiliaryButton = viewController.getAuxiliaryButton()

        auxiliaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.auxiliaryButtonTapped)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_primary_button() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButtonTitle = viewController.primaryActionButton().title(for: .normal)

        // Then
        XCTAssertEqual(primaryButtonTitle, viewModel.primaryButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_primary_button_is_tapped() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButton = viewController.primaryActionButton()
        primaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.primaryButtonTapped)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_secondary_button() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let secondaryActionButtonTitle = viewController.secondaryActionButton().title(for: .normal)

        // Then
        XCTAssertEqual(secondaryActionButtonTitle, viewModel.secondaryButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_secondary_button_is_tapped() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let secondaryButton = viewController.secondaryActionButton()
        secondaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.secondaryButtonTapped)
    }

    func test_viewController_informs_viewModel_when_the_view_is_loaded() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        XCTAssertFalse(viewModel.viewDidLoadTriggered)

        // When
        _ = try XCTUnwrap(viewController.view)

        // Then
        XCTAssertTrue(viewModel.viewDidLoadTriggered)
    }
}


private final class ErrorViewModel: ULErrorViewModel {
    let image: UIImage = .loginNoJetpackError

    let text: NSAttributedString = NSAttributedString(string: "woocommerce")

    let isAuxiliaryButtonHidden: Bool = false

    let auxiliaryButtonTitle: String = "Aux"

    let primaryButtonTitle: String = "Primary"

    let secondaryButtonTitle: String = "Secondary"

    var primaryButtonTapped: Bool = false
    var secondaryButtonTapped: Bool = false
    var auxiliaryButtonTapped: Bool = false
    var viewDidLoadTriggered = false

    func didTapPrimaryButton(in viewController: UIViewController?) {
        primaryButtonTapped = true
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        secondaryButtonTapped = true
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        auxiliaryButtonTapped = true
    }

    func viewDidLoad() {
        viewDidLoadTriggered = true
    }
}

// MARK: - WordPressAuthenticator Initialization

private extension ULErrorViewControllerTests {
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
