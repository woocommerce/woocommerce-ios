import Foundation
import Yosemite
@testable import WooCommerce

struct MockOrderRefundsOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol {
    private let determineRefundableOrderItems: [RefundableOrderItem]
    private let isAnythingToRefund: Bool

    init(determineRefundableOrderItems: [RefundableOrderItem] = [], isAnythingToRefund: Bool = false) {
        self.determineRefundableOrderItems = determineRefundableOrderItems
        self.isAnythingToRefund = isAnythingToRefund
    }

    func determineRefundableOrderItems(from order: Order, with refunds: [Refund]) -> [RefundableOrderItem] {
        determineRefundableOrderItems
    }

    func isAnythingToRefund(from order: Order, with refunds: [Refund], currencyFormatter: CurrencyFormatter) -> Bool {
        isAnythingToRefund
    }
}
