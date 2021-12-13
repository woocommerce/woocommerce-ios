import XCTest
@testable import WooCommerce
import Yosemite

final class Collection_ShippingLabelTests: XCTestCase {
    func test_nonRefunded_returns_empty_array_when_all_shipping_labels_are_refunded() {
        // Given
        let shippingLabels: [ShippingLabel] = [
            MockShippingLabel.emptyLabel().copy(refund: .init(dateRequested: Date(), status: .pending)),
            MockShippingLabel.emptyLabel().copy(refund: .init(dateRequested: Date(), status: .pending)),
            MockShippingLabel.emptyLabel().copy(refund: .init(dateRequested: Date(), status: .pending))
        ]

        // When
        let nonRefunded = shippingLabels.nonRefunded

        // Then
        XCTAssertEqual(nonRefunded, [])
    }

    func test_nonRefunded_returns_non_refunded_shipping_labels() {
        // Given
        let nonRefundedShippingLabel = MockShippingLabel.emptyLabel().copy(refund: nil)
        let refundedShippingLabels: [ShippingLabel] = [
            MockShippingLabel.emptyLabel().copy(refund: .init(dateRequested: Date(), status: .pending)),
            MockShippingLabel.emptyLabel().copy(refund: .init(dateRequested: Date(), status: .pending)),
            MockShippingLabel.emptyLabel().copy(refund: .init(dateRequested: Date(), status: .pending))
        ]
        let shippingLabels = refundedShippingLabels + [nonRefundedShippingLabel]

        // When
        let nonRefunded = shippingLabels.nonRefunded

        // Then
        XCTAssertEqual(nonRefunded, [nonRefundedShippingLabel])
    }
}
