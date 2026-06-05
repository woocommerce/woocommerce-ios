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
    /// Remote-added fees are allowed so server plugins can add their own charges.
    func matches(order: Order?) -> Bool {
        return comparison(with: order).matches
    }

    func extraActiveFeesCount(order: Order?) -> Int {
        return comparison(with: order).extraFeesCount
    }

    func comparison(with order: Order?) -> (matches: Bool, extraFeesCount: Int) {
        let activeOrderFees = order?.fees.filter { !$0.isDeleted } ?? []
        let cartSummaries = self
            .map { CustomAmountSummary(name: $0.name, amount: $0.amount) }
        var unmatchedOrderSummaries = activeOrderFees
            .map { CustomAmountSummary(name: $0.name ?? "", amount: $0.total) }

        for cartSummary in cartSummaries {
            guard let matchingIndex = unmatchedOrderSummaries.firstIndex(of: cartSummary) else {
                return (matches: false, extraFeesCount: unmatchedOrderSummaries.count)
            }
            unmatchedOrderSummaries.remove(at: matchingIndex)
        }

        return (matches: true, extraFeesCount: unmatchedOrderSummaries.count)
    }

    private struct CustomAmountSummary: Hashable {
        let name: String
        let amount: String
    }
}
