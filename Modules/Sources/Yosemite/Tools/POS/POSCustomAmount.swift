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
    ///
    /// Duplicate `id`s are unexpected (the cart upserts by `id`), but since this is public API
    /// a collision on either side is treated as a mismatch so the caller errs toward re-syncing
    /// rather than silently masking a change (e.g. `[A, B]` vs `[A, A]` with equal tax flags).
    public func taxableIntentMatches(_ previous: [POSCustomAmount]) -> Bool {
        guard let current = taxableFlagsByID,
              let previous = previous.taxableFlagsByID else {
            return false
        }
        return current == previous
    }

    /// Maps each amount's `id` to its `isTaxable` flag, or `nil` if any `id` appears more than once.
    private var taxableFlagsByID: [UUID: Bool]? {
        var result = [UUID: Bool](minimumCapacity: count)
        for amount in self where result.updateValue(amount.isTaxable, forKey: amount.id) != nil {
            return nil
        }
        return result
    }

    private struct CustomAmountSummary: Hashable {
        let name: String
        let amount: Decimal

        init(name: String, amount: String) {
            self.name = name
            // Compare amounts numerically. The cart stores the merchant's input in the store's
            // decimal separator with no fraction padding (e.g. "15" or "15,00"), while the synced
            // order's fee total comes back canonical ("15.00"); a raw string compare treats those
            // as different. Transliterate to Latin digits first (a store may display Arabic-Indic or
            // other numerals), then map any comma to a period, for a locale-independent value to parse.
            let latinDigits = amount.applyingTransform(.toLatin, reverse: false) ?? amount
            let normalized = latinDigits.replacingOccurrences(of: ",", with: ".")
            self.amount = Decimal(string: normalized, locale: Self.posixLocale) ?? .zero
        }

        private static let posixLocale = Locale(identifier: "en_US_POSIX")
    }
}
