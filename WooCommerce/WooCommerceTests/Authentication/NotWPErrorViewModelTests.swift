import XCTest
@testable import WooCommerce

final class NotWPErrorViewModelTests: XCTestCase {

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = NotWPErrorViewModel()

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_error_message() {
        // Given
        let viewModel = NotWPErrorViewModel()
        let expectation = NSAttributedString(string: Expectations.errorMessage)

        // When
        let errorMessage = viewModel.text

        // Then
        XCTAssertEqual(errorMessage, expectation)
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = NotWPErrorViewModel()

        // When
        let isHidden = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertTrue(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = NotWPErrorViewModel()

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, "")
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = NotWPErrorViewModel()

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = NotWPErrorViewModel()

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }
}


private extension NotWPErrorViewModelTests {
    private enum Expectations {
        static let image = UIImage.loginNoWordPressError

        static let errorMessage =
            NSLocalizedString("We were not able to detect a WordPress site at the address you entered."
                                + " Please make sure WordPress is installed and that you are running"
                                + " the latest available version.",
                              comment: "Message explaining that WordPress was not detected.")

        static let primaryButtonTitle = NSLocalizedString("Enter Another Store",
                                                          comment: "Action button linking to instructions for enter another store."
                                                          + "Presented when logging in with a site address that is not a WordPress site")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")
    }
}
