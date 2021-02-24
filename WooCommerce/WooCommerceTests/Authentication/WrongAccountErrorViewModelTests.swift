import XCTest
@testable import WooCommerce

final class WrongAccountErrorViewModelTests: XCTestCase {

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url)

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url)

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, Expectations.findYourConnectedEmail)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url)

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_log_out_button() {
        // Given
        let viewModel = WrongAccountErrorViewModel(siteURL: Expectations.url)

        // When
        let logoutButtonTitle = viewModel.logOutButtonTitle

        // Then
        XCTAssertEqual(logoutButtonTitle, Expectations.logOutButtonTitle)
    }
}


private extension WrongAccountErrorViewModelTests {
    private enum Expectations {
        static let url = "https://woocommerce.com"
        static let image = UIImage.errorImage

        static let primaryButtonTitle = NSLocalizedString("See Connected Stores",
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
