import XCTest
import Yosemite
import WordPressAuthenticator
@testable import WooCommerce

final class JetpackConnectionErrorViewModelTests: XCTestCase {

    private let credentials = WordPressOrgCredentials(username: "test", password: "pwd", xmlrpc: "http://test.com/xmlrpc.php", options: [:])
    private let siteURL = "http://test.com"

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = JetpackConnectionErrorViewModel(siteURL: siteURL, credentials: credentials, onJetpackSetupCompletion: { _ in })

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_error_message() {
        // Given
        let viewModel = JetpackConnectionErrorViewModel(siteURL: siteURL, credentials: credentials, onJetpackSetupCompletion: { _ in })
        let expectation = Expectations.noJetpackEmail.replacingOccurrences(of: "%@", with: "test.com")

        // When
        let errorMessage = viewModel.text.string

        // Then
        XCTAssertEqual(errorMessage, expectation)
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = JetpackConnectionErrorViewModel(siteURL: siteURL, credentials: credentials, onJetpackSetupCompletion: { _ in })

        // When
        let isHidden = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertTrue(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = JetpackConnectionErrorViewModel(siteURL: siteURL, credentials: credentials, onJetpackSetupCompletion: { _ in })

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, "")
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = JetpackConnectionErrorViewModel(siteURL: siteURL, credentials: credentials, onJetpackSetupCompletion: { _ in })

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = JetpackConnectionErrorViewModel(siteURL: siteURL, credentials: credentials, onJetpackSetupCompletion: { _ in })

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }

    func test_web_view_is_presented_when_tapping_primary_button() throws {
        // Given
        let expectedURL = try XCTUnwrap(URL(string: "http://jetpack.wordpress.com/jetpack.authorize/1/"))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionURL(_, _, let completion):
                completion(.success(expectedURL))
            }
        }
        let viewModel = JetpackConnectionErrorViewModel(siteURL: siteURL, credentials: credentials, stores: stores, onJetpackSetupCompletion: { _ in })
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)

        // When
        viewModel.didTapPrimaryButton(in: viewController)
        waitUntil {
            navigationController.viewControllers.containsMoreThanOne
        }

        // Then
        XCTAssertTrue(navigationController.topViewController is PluginSetupWebViewController)
    }
}

private extension JetpackConnectionErrorViewModelTests {
    enum Expectations {
        static let image = UIImage.productErrorImage

        static let noJetpackEmail = NSLocalizedString(
            "It looks like your account is not connected to %@'s Jetpack",
            comment: "Message explaining that the entered site credentials belong to an account that is not connected to the site's Jetpack. "
            + "Reads like 'It looks like your account is not connected to awebsite.com's Jetpack")

        static let primaryButtonTitle = NSLocalizedString(
            "Connect Jetpack to your account",
            comment: "Button linking to web view for setting up Jetpack connection. " +
            "Presented when logging in with store credentials of an account not connected to the site's Jetpack")

        static let secondaryButtonTitle = NSLocalizedString(
            "Log In With Another Account",
            comment: "Action button that will restart the login flow." +
            "Presented when logging in with store credentials of an account not connected to the site's Jetpack"
        )
    }
}
