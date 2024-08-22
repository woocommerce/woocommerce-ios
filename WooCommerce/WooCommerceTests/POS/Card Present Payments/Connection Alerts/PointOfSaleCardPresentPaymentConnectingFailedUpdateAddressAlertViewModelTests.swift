import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: {},
            cancelSearchAction: {})

        XCTAssertPropertyCount(sut,
                               expectedCount: 9,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

}
