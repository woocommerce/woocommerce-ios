import Foundation

public struct POSRefundsResult {
    public let refunds: [POSRefund]
    public let isFullyRefunded: Bool
    public let supportsAutomaticRefund: Bool

    public init(refunds: [POSRefund], isFullyRefunded: Bool, supportsAutomaticRefund: Bool) {
        self.refunds = refunds
        self.isFullyRefunded = isFullyRefunded
        self.supportsAutomaticRefund = supportsAutomaticRefund
    }
}

public protocol POSRefundsServiceProtocol {
    func providePointOfSaleRefunds(for order: POSOrder) async throws -> POSRefundsResult
    func loadOrderRefunds(for order: POSOrder) async throws -> [POSOrderRefund]
}
