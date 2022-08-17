import XCTest
import enum WordPressAuthenticator.SignInError
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
        XCTAssertEqual(auxiliaryButtonTitle, AuthenticationConstants.whatIsWPComLinkTitle)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = NotWPAccountViewModel()

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.loginWithSiteAddressTitle)
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

    func test_primary_button_title_is_login_with_site_address_for_invalidWPComEmail_from_wpCom_error() {
        // Given
        let viewModel = NotWPAccountViewModel(error: SignInError.invalidWPComEmail(source: .wpCom))

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.loginWithSiteAddressTitle)
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

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = NotWPAccountViewModel()

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.restartLoginTitle)
    }
}


private extension NotWPAccountViewModelTests {
    private enum Expectations {
        static let image = UIImage.loginNoWordPressError
        static let errorMessage = NSLocalizedString("This email isn't used with a WordPress.com account.",
                                                    comment: "Message explaining that an email is not associated with a WordPress.com account. "
                                                        + "Presented when logging in with an email address that is not a WordPress.com account")

        static let loginWithSiteAddressTitle = NSLocalizedString("Log in with your store address",
                                                                 comment: "Action button linking to instructions for enter another store."
                                                                 + "Presented when logging in with an email address that is not a WordPress.com account")

        static let restartLoginTitle = NSLocalizedString("Log in with another account",
                                                         comment: "Action button that will restart the login flow."
                                                         + "Presented when logging in with an email address that does not match a WordPress.com account")
    }
}

private extension NotWPAccountViewModel {
    convenience init() {
        self.init(error: SignInError.invalidWPComEmail(source: .wpCom))
    }
}
