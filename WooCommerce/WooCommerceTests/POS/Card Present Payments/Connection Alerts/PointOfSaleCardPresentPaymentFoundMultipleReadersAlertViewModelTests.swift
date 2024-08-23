import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel(
            readerIDs: ["abc"],
            selectionHandler: { _ in })

        XCTAssertPropertyCount(sut,
                               expectedCount: 4,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

    func test_manual_hashable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel(
            readerIDs: ["abc"],
            selectionHandler: { _ in })

        XCTAssertPropertyCount(sut,
                               expectedCount: 4,
                               messageHint: "Please check that the manual hashable conformance includes new properties.")
    }

}
