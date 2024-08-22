import XCTest
@testable import WooCommerce

final class CardPresentPaymentsModalButtonViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = CardPresentPaymentsModalButtonViewModel(title: "Title", actionHandler: {})
        XCTAssertPropertyCount(sut,
                               expectedCount: 3,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

}
