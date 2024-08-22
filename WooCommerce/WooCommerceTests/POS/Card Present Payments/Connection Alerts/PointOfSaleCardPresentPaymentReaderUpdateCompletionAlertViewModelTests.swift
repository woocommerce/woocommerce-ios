import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModelTests: XCTestCase {

    func test_manual_hashable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel()

        XCTAssertPropertyCount(sut,
                               expectedCount: 3,
                               messageHint: "Please check that the manual hashable conformance includes new properties.")
    }

}
