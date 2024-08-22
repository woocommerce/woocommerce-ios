import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel(
            readerIDs: ["abc"],
            selectionHandler: { _ in })

        XCTAssertPropertyCount(sut,
                               expectedCount: 3,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

}
