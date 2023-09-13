import Foundation
import Yosemite

enum TaxRateOrderApplicabilityStatus {
    case applicable
    case notApplicable(reason: TaxRateOrderNotApplicabilityStatusReason)
}

enum TaxRateOrderNotApplicabilityStatusReason {
    case emptyOrder
    case doesNotApplyToOrderItems
    case notEnoughPriority
}

/// Determines whether a tax rate applies to a given order, and the reason why it doesn't in the negative case.
/// The algorithm is probably not 100% exhaustive, but it's enough for our purposes.
///
struct TaxRateOrderApplicabilityDeterminer {
    func taxRateOrderApplicabilityStatus(taxRate: TaxRate, order: Order) -> TaxRateOrderApplicabilityStatus {
        if order.taxes.first(where: { $0.rateID == taxRate.id }) != nil {
            return .applicable
        } else if order.items.isEmpty {
            return .notApplicable(reason: .emptyOrder)
        } else if order.taxes.isEmpty || order.items.first(where: { $0.taxClass == taxRate.taxRateClass }) == nil {
            return .notApplicable(reason: .doesNotApplyToOrderItems)
        } else {
            return .notApplicable(reason: .notEnoughPriority)
        }
    }
}
