import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingCreateLabelsViewModelTests: XCTestCase {
    func test_inits_with_expected_values() {
        // Given
        let order = Order.fake()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        XCTAssertFalse(viewModel.markOrderComplete)
    }

    func test_onLabelPurchase_notifies_when_order_should_not_be_marked_complete() {
        // Given
        let order = Order.fake()

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: order, onLabelPurchase: { complete in
                promise(complete)
            })
            viewModel.markOrderComplete = false
            viewModel.purchaseLabel()
        }

        // Then
        XCTAssertFalse(markOrderComplete)
    }

    func test_onLabelPurchase_notifies_when_order_should_be_marked_complete() {
        // Given
        let order = Order.fake()

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: order, onLabelPurchase: { complete in
                promise(complete)
            })
            viewModel.markOrderComplete = true
            viewModel.purchaseLabel()
        }

        // Then
        XCTAssertTrue(markOrderComplete)
    }
}
