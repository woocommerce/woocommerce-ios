import Foundation

enum UpgradeViewState: Equatable {
    case loading
    case loaded(WooWPComPlan)
    case purchasing(WooWPComPlan)
    case waiting(WooWPComPlan)
    case completed(WooWPComPlan)
    case prePurchaseError(PrePurchaseError)
    case purchaseUpgradeError(PurchaseUpgradeError)

    var shouldShowPlanDetailsView: Bool {
        switch self {
        case .loading, .loaded, .purchasing, .prePurchaseError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Equatable conformance
extension UpgradeViewState {
    static func ==(lhs: UpgradeViewState, rhs: UpgradeViewState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.prePurchaseError(let lhsError), .prePurchaseError(let rhsError)):
            return lhsError == rhsError
        default:
            // TODO: Needs conformance for the rest of cases
            return false
        }
    }
}
