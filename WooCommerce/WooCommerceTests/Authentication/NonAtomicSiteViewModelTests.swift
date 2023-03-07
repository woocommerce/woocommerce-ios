import XCTest
import Yosemite
@testable import WooCommerce

final class NonAtomicSiteViewModelTests: XCTestCase {

    func test_viewmodel_provides_expected_title() {
        // Given
        let site = Site.fake().copy(name: "Test")
        let viewModel = NonAtomicSiteViewModel(site: site)

        // When
        let title = viewModel.title

        // Then
        XCTAssertEqual(title, site.name)
    }

    func test_viewmodel_provides_expected_image() {
        // Given
        let viewModel = NonAtomicSiteViewModel(site: Site.fake())

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewmodel_provides_expected_error_message() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let viewModel = NonAtomicSiteViewModel(site: site)
        let expectation = Expectations.errorMessage.replacingOccurrences(of: "%@", with: "test.com")

        // When
        let errorMessage = viewModel.text.string

        // Then
        XCTAssertEqual(errorMessage, expectation)
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        // Given
        let viewModel = NonAtomicSiteViewModel(site: Site.fake())

        // When
        let isHidden = viewModel.isAuxiliaryButtonHidden

        // Then
        XCTAssertTrue(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        // Given
        let viewModel = NonAtomicSiteViewModel(site: Site.fake())

        // When
        let auxiliaryButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, "")
    }

    func test_viewmodel_provides_expected_visibility_for_primary_button() {
        // Given
        let viewModel = NonAtomicSiteViewModel(site: Site.fake())

        // When
        let isHidden = viewModel.isPrimaryButtonHidden

        // Then
        XCTAssertTrue(isHidden)
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        // Given
        let viewModel = NonAtomicSiteViewModel(site: Site.fake())

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, "")
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        // Given
        let viewModel = NonAtomicSiteViewModel(site: Site.fake())

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }

}

private extension NonAtomicSiteViewModelTests {
    enum Expectations {
        static let image = UIImage.loginNoWordPressError

        static let errorMessage = NSLocalizedString(
            "It seems that your site %@ is a simple WordPress.com site that cannot install plugins. Please upgrade your plan to use WooCommerce.",
            comment: "An error message displayed when the user tries to log in to the app with a simple WP.com site. " +
            "Reads like: It seems that your site google.com is a simple WordPress.com site that cannot install plugins. " +
            "Please upgrade your plan to use WooCommerce."
        )

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when the user tries to log in to the app with a simple WP.com site.")
    }
}
