import XCTest
@testable import WooCommerce

final class ApplicationPasswordDisabledViewModelTests: XCTestCase {

    private let testURL = "https://test.com"

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
        let expectation = Expectations.errorMessage.replacingOccurrences(of: "%@", with: "test.com")

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
}

private extension ApplicationPasswordDisabledViewModelTests {
    enum Expectations {
        static let image = UIImage.errorImage

        static let errorMessage = NSLocalizedString(
            "It seems that your site %@ has Application Password disabled. Please enable it to use the WooCommerce app.",
            comment: "An error message displayed when the user tries to log in to the app with site credentials but has application password disabled. " +
            "Reads like: It seems that your site google.com has Application Password disabled. " +
            "Please enable it to use the WooCommerce app."
        )
        static let secondaryButtonTitle = NSLocalizedString(
            "Log In With Another Account",
            comment: "Action button that will restart the login flow."
            + "Presented when the user tries to log in to the app with site credentials but has application password disabled."
        )
        static let auxiliaryButtonTitle = NSLocalizedString(
            "What is Application Password?",
            comment: "Button that will navigate to a web page explaining Application Password"
        )
        static let primaryButtonTitle = NSLocalizedString(
            "Log in with WordPress.com",
            comment: "Button that will navigate to the authentication flow with WP.com"
        )
    }
}
