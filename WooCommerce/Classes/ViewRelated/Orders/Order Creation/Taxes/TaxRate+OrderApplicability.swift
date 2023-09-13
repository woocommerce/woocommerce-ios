import Foundation
import Yosemite

extension TaxRate {
    /// Returns the string to show in the notice of the Editable Order Details depending on whether the tax rate applies to the order or not.
    /// 
    func orderDetailsApplicabilityText(to order: Order) -> String? {
        orderApplicabilityStatus(order: order).orderDetailsText
    }
}

private enum TaxRateOrderApplicabilityStatus {
    case applicable
    case notApplicable(reason: TaxRateOrderNotApplicabilityStatusReason)

    var orderDetailsText: String? {
        switch self {
        case .applicable:
            return NSLocalizedString("Tax rate added automatically",
                                     comment: "Notice in editable order details when the tax rate was added to the order")
        case .notApplicable(reason: .emptyOrder):
            return nil
        case .notApplicable(reason: .doesNotApplyToOrderItems):
            return NSLocalizedString("This rate doesn't apply to these products",
                                     comment: "Notice in editable order details when the tax rate cannot apply to the products")
        case .notApplicable(reason: .notEnoughPriority):
            return NSLocalizedString("This rate does not apply because another rate has higher priority",
                                     comment: "Notice in editable order details when another tax rate has higher priority")
        }
    }
}

private enum TaxRateOrderNotApplicabilityStatusReason {
    case emptyOrder
    case doesNotApplyToOrderItems
    case notEnoughPriority
}

/// Determines whether a tax rate applies to a given order, and the reason why it doesn't in the negative case.
/// The algorithm is probably not 100% exhaustive, but it's enough for our purposes.
///
private extension TaxRate {
     func orderApplicabilityStatus(order: Order) -> TaxRateOrderApplicabilityStatus {
        if order.taxes.first(where: { $0.rateID == id }) != nil {
            return .applicable
        } else if order.items.isEmpty {
            return .notApplicable(reason: .emptyOrder)
        } else if order.taxes.isEmpty || order.items.first(where: { $0.taxClass == taxRateClass }) == nil {
            return .notApplicable(reason: .doesNotApplyToOrderItems)
        } else {
            return .notApplicable(reason: .notEnoughPriority)
        }
    }
}
