import Foundation

public struct POSRefundsResult {
    public let refunds: [POSRefund]
    public let isFullyRefunded: Bool

    public init(refunds: [POSRefund], isFullyRefunded: Bool) {
        self.refunds = refunds
        self.isFullyRefunded = isFullyRefunded
    }
}

public protocol POSRefundsServiceProtocol {
    func providePointOfSaleRefunds(for order: POSOrder) async throws -> POSRefundsResult
}
