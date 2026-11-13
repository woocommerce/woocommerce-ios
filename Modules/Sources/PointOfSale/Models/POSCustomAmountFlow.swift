import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSCustomAmount

/// The full-screen custom amount flow that is open, if any.
enum POSCustomAmountFlow: Identifiable, Equatable {
    /// Started from the entry row in the products list.
    case add
    /// Started from a custom amount row in the cart.
    case edit(POSCustomAmount)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let customAmount):
            return "edit-" + customAmount.id.uuidString
        }
    }

    var editingCustomAmount: POSCustomAmount? {
        switch self {
        case .add:
            return nil
        case .edit(let customAmount):
            return customAmount
        }
    }

    var analyticsMode: WooAnalyticsEvent.PointOfSale.CustomAmountMode {
        switch self {
        case .add:
            return .add
        case .edit:
            return .edit
        }
    }
}
