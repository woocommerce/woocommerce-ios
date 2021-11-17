import XCTest
@testable import WooCommerce
import Yosemite

class NewOrderViewModelTests: XCTestCase {

    func test_view_model_starts_with_create_button_disabled() {
        // Given
        let viewModel = NewOrderViewModel(siteID: 123, onCompletion: { _ in })

        // Then
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }
}
