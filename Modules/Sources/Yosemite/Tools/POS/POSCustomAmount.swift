import Foundation
import struct NetworkingCore.Order

/// Cart-side representation of a custom amount (a one-off charge added by the merchant
/// during a Point of Sale order). Carries the merchant-entered values; the equivalent
/// fee on a synced order is `OrderFeeLine`.
public struct POSCustomAmount: Equatable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let amount: String
    public let isTaxable: Bool

    public init(id: UUID = UUID(),
                name: String,
                amount: String,
                isTaxable: Bool) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isTaxable = isTaxable
    }
}

extension [POSCustomAmount] {
    /// Compares the cart's custom amounts against an order's fee lines for sync parity.
    ///
    /// Matching is intentionally on `(name, amount)` only; `isTaxable` is excluded
    /// because the server's tax decision can legitimately differ from the cart's
    /// intent (e.g. a tax-exempt customer or store-level tax-class override). Treating
    /// a divergence on `isTaxable` as a mismatch would force a redundant resync every
    /// time the merchant places a taxable custom amount on a non-taxable order.
    func matches(order: Order?) -> Bool {
        let activeOrderFees = order?.fees.filter { !$0.isDeleted } ?? []
        guard self.count == activeOrderFees.count else {
            return false
        }

        let cartSummaries = self
            .map { CustomAmountSummary(name: $0.name, amount: $0.amount) }
            .sorted()
        let orderSummaries = activeOrderFees
            .map { CustomAmountSummary(name: $0.name ?? "", amount: $0.total) }
            .sorted()
        return cartSummaries == orderSummaries
    }

    private struct CustomAmountSummary: Hashable, Comparable {
        let name: String
        let amount: String

        static func < (lhs: Self, rhs: Self) -> Bool {
            (lhs.name, lhs.amount) < (rhs.name, rhs.amount)
        }
    }
}
