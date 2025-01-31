import XCTest
import SafariServices
import WordPressAuthenticator
@testable import WooCommerce

final class ApplicationPasswordDisabledViewModelTests: XCTestCase {

    private let testURL = "https://test.com"
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController
        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_error_message() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)
        let expectation = Expectations.errorMessage.replacingOccurrences(of: "%1$@", with: "test.com")

        // When
        let errorMessage = viewModel.text.string

        // Then
        XCTAssertEqual(errorMessage, expectation)
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        let isHidden = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertFalse(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, Expectations.auxiliaryButtonTitle)
    }

    func test_viewmodel_provides_expected_visibility_for_primary_button() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        let isHidden = viewModel.isPrimaryButtonHidden

        // Then
        XCTAssertFalse(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_visibility_for_secondary_button() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        let isHidden = viewModel.isSecondaryButtonHidden

        // Then
        XCTAssertFalse(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }

    func test_didTapAuxiliaryButton_presents_a_web_view() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)

        // When
        viewModel.didTapAuxiliaryButton(in: navigationController)

        // Then
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        XCTAssertTrue(navigationController.presentedViewController is SFSafariViewController)
    }

    func test_didTapPrimaryButton_navigates_to_correct_view_controller() {
        // Given
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: testURL)
        let viewController1 = UIViewController()
        let viewController2 = UIViewController()
        let viewController3 = UIViewController()

        navigationController.viewControllers = [viewController1, viewController2, viewController3]
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        XCTAssertEqual(viewController3.navigationController, navigationController, "viewController3 should be part of the navigationController's stack")

        // When
        viewModel.didTapPrimaryButton(in: viewController3)

        waitUntil(timeout: Constants.expectationTimeout) {
            return self.navigationController.viewControllers.count == 1 &&
            self.navigationController.topViewController === viewController1
        }

        // Then
        XCTAssertEqual(navigationController.viewControllers.count, 1, "After the action, navigationController's stack should contain only one view controller")
        XCTAssertEqual(navigationController.topViewController, viewController1, "topViewController should be viewController1")
    }
}

private extension ApplicationPasswordDisabledViewModelTests {
    enum Expectations {
        static let image = UIImage.errorImage

        static let errorMessage = NSLocalizedString(
            "applicationPasswordDisabled.errorMessage",
            value: "It seems that your site %1$@ has Application Password disabled. Please enable it to use the WooCommerce app.",
            comment: "An error message displayed when the user tries to log in to the app with site credentials but has application password disabled. " +
            "Reads like: It seems that your site google.com has Application Password disabled. " +
            "Please enable it to use the WooCommerce app."
        )
        static let secondaryButtonTitle = NSLocalizedString(
            "applicationPasswordDisabled.secondaryButtonTitle",
            value: "Log In With Another Account",
            comment: "Action button that will restart the login flow."
            + "Presented when the user tries to log in to the app with site credentials but has application password disabled."
        )
        static let auxiliaryButtonTitle = NSLocalizedString(
            "applicationPasswordDisabled.auxiliaryButtonTitle",
            value: "What is Application Password?",
            comment: "Button that will navigate to a web page explaining Application Password"
        )
        static let primaryButtonTitle = NSLocalizedString(
            "applicationPasswordDisabled.retry.buttonTitle",
            value: "Retry",
            comment: "Button to retry fetching application password authorization if application password is disabled"
        )
    }
}
