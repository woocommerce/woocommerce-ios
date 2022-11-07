import XCTest
@testable import WooCommerce

final class XMLRPCErrorViewModelTests: XCTestCase {
    private var sut: XMLRPCErrorViewModel!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = XMLRPCErrorViewModel(siteAddress: "http://test.com")
    }

    override func tearDown() {
        sut = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_viewmodel_provides_expected_image() {
        XCTAssertEqual(sut.image, Expectations.image)
    }

    func test_viewmodel_provides_expected_error_message() {
        // Given
        let site = "https://test.com"
        let viewModel = XMLRPCErrorViewModel(siteAddress: site)

        // Then
        let xmlrpcURL = site + "/xmlrpc.php"
        XCTAssertEqual(viewModel.text.string, String(format: Expectations.errorMessage, xmlrpcURL))
    }

    func test_viewmodel_provides_expected_visibility_for_auxiliary_button() {
        XCTAssertTrue(sut.isAuxiliaryButtonHidden)
    }

    func test_viewmodel_provides_expected_title_for_auxiliary_button() {
        XCTAssertEqual(sut.auxiliaryButtonTitle, "")
    }

    func test_viewmodel_provides_expected_title_for_primary_button() {
        XCTAssertEqual(sut.primaryButtonTitle, Expectations.tryAnotherAddress)
    }

    func test_viewmodel_provides_expected_visibility_for_secondary_button() {
        XCTAssertTrue(sut.isSecondaryButtonHidden)
    }

    func test_viewmodel_provides_expected_title_for_secondary_button() {
        XCTAssertEqual(sut.secondaryButtonTitle, "")

    }
}


private extension XMLRPCErrorViewModelTests {
    private enum Expectations {
        static let image = UIImage.errorImage

        static let errorMessage = NSLocalizedString("While your site is publicly accessible, we cannot access your site’s XML-RPC file. \n\n%@\n\n"
                                                    + " You will need to contact your hosting provider to ensure that XML-RPC is enabled on your server.",
                                                    comment: "Message explaining that /xmlrpc.php was not accessible.")

        static let tryAnotherAddress = NSLocalizedString("Try Another Address",
                                                         comment: "Action button that will restart the login flow."
                                                         + "Presented when logging in with an email address that does not match a WordPress.com account")
    }
}
