import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
            let sut = PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel(
                progress: 0.5,
                cancel: {})

            XCTAssertPropertyCount(sut,
                                   expectedCount: 8,
                                   messageHint: "Please check that the manual equatable conformance includes new properties.")
        }

    func test_manual_hashable_conformance_number_of_properties_unchanged() {
            let sut = PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel(
                progress: 0.5,
                cancel: {})

            XCTAssertPropertyCount(sut,
                                   expectedCount: 8,
                                   messageHint: "Please check that the manual hashable conformance includes new properties.")
        }

}
