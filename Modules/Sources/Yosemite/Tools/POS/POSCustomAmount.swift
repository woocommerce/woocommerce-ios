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

    /// Returns `true` when the taxable intent of these custom amounts matches a
    /// previously-synced set, comparing each amount by `id`.
    ///
    /// `matches(order:)` deliberately ignores `isTaxable` (the server's tax decision can
    /// legitimately differ from the cart's intent), so a merchant toggling "Charge taxes"
    /// on an otherwise-identical amount would never re-sync. This method closes that gap by
    /// comparing against the cart's *own* record of what it last asked the server for —
    /// never against the server's returned tax status. Callers (the order controller) use a
    /// divergence here to force a resync, without reintroducing the redundant resync loop
    /// that comparing against the server's tax decision would cause.
    public func taxableIntentMatches(_ previous: [POSCustomAmount]) -> Bool {
        guard self.count == previous.count else {
            return false
        }

        let previousTaxableByID = Dictionary(previous.map { ($0.id, $0.isTaxable) },
                                             uniquingKeysWith: { first, _ in first })
        return self.allSatisfy { amount in
            previousTaxableByID[amount.id] == amount.isTaxable
        }
    }

    private struct CustomAmountSummary: Hashable, Comparable {
        let name: String
        let amount: String

        static func < (lhs: Self, rhs: Self) -> Bool {
            (lhs.name, lhs.amount) < (rhs.name, rhs.amount)
        }
    }
}
