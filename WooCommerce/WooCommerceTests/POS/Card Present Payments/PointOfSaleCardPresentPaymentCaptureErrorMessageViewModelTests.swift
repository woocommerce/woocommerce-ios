import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentCaptureErrorMessageViewModelTests: XCTestCase {
    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(tryAgainButtonAction: {}, newOrderButtonAction: {})
        XCTAssertPropertyCount(sut,
                               expectedCount: 7,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }
}
