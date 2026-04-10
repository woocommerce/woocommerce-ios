import XCTest
@testable import PointOfSale

final class PointOfSaleCardPresentPaymentCaptureErrorMessageViewModelTests: XCTestCase {
    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(tryAgainButtonAction: {}, newOrderButtonAction: {})
        XCTAssertPropertyCount(sut,
                               expectedCount: 6,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }
}
