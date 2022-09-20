import XCTest
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
}


private extension WrongAccountErrorViewModelTests {
    private enum Expectations {
        static let url = "https://woocommerce.com"
        static let image = UIImage.productErrorImage

        static let primaryButtonTitle = NSLocalizedString("Connect Jetpack",
                                                          comment: "Action button to handle Jetpack connection."
                                                          + "Presented when logging in with a self-hosted site that does not match the account entered")

        static let secondaryButtonTitle = NSLocalizedString("See Connected Stores",
                                                            comment: "Action button linking to a list of connected stores."
                                                            + "Presented when logging in with a store address that does not match the account entered")

        static let logOutButtonTitle = NSLocalizedString("Log Out",
                                                          comment: "Action button triggering a Log Out."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let findYourConnectedEmail = NSLocalizedString("Find your connected email",
                                                     comment: "Button linking to webview explaining how to find your connected email"
                                                        + "Presented when logging in with a store address that does not match the account entered")
    }
}
