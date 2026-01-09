import Foundation

public struct POSRefundItem: Equatable, Hashable {
    public let quantity: Decimal

    public init(quantity: Decimal) {
        self.quantity = quantity
    }
}
