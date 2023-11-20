import Foundation
import Yosemite
import WooFoundation
@testable import WooCommerce

struct MockOrderRefundsOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol {
    private let determineRefundableOrderItems: [RefundableOrderItem]
    private let isAnythingToRefund: Bool
    private let shouldRefundCustomAmountsByDefault: Bool

    init(determineRefundableOrderItems: [RefundableOrderItem] = [], isAnythingToRefund: Bool = false,
        shouldRefundCustomAmountsByDefault: Bool = false) {
        self.determineRefundableOrderItems = determineRefundableOrderItems
        self.isAnythingToRefund = isAnythingToRefund
        self.shouldRefundCustomAmountsByDefault = shouldRefundCustomAmountsByDefault
    }

    func determineRefundableOrderItems(from order: Order, with refunds: [Refund]) -> [RefundableOrderItem] {
        determineRefundableOrderItems
    }

    func isAnythingToRefund(from order: Order, with refunds: [Refund], currencyFormatter: CurrencyFormatter) -> Bool {
        isAnythingToRefund
    }

    func shouldRefundCustomAmountsByDefault(from order: Order) -> Bool {
        shouldRefundCustomAmountsByDefault
    }
}
