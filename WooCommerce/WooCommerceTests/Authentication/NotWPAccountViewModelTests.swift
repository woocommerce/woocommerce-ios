import XCTest
@testable import WooCommerce

final class NotWPAccountViewModelTests: XCTestCase {

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
        XCTAssertEqual(auxiliaryButtonTitle, Expectations.needHelpFindingEmail)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = NotWPAccountViewModel()

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = NotWPAccountViewModel()

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }
}


private extension NotWPAccountViewModelTests {
    private enum Expectations {
        static let image = UIImage.loginNoWordPressError
        static let errorMessage = NSLocalizedString("It looks like this email isn't associated with a WordPress.com account.",
                                                    comment: "Message explaining that an email is not associated with a WordPress.com account. "
                                                        + "Presented when logging in with an email address that is not a WordPress.com account")

        static let needHelpFindingEmail = NSLocalizedString("Need help finding the connected email?",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let primaryButtonTitle = NSLocalizedString("Enter Your Store Address",
                                                          comment: "Action button linking to instructions for enter another store."
                                                          + "Presented when logging in with an email address that is not a WordPress.com account")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with an email address that does not match a WordPress.com account")
    }
}
