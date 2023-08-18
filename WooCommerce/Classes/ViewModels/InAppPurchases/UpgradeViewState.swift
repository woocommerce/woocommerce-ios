import Foundation

enum UpgradeViewState: Equatable {
    case loading
    case loaded([WooWPComPlan])
    case waiting(WooWPComPlan)
    case completed(WooWPComPlan)
    case prePurchaseError(PrePurchaseError)
    case purchaseUpgradeError(PurchaseUpgradeError)

    var analyticsStep: WooAnalyticsEvent.InAppPurchases.Step? {
        switch self {
        case .loading:
            return nil
        case .loaded:
            return .planDetails
        case .waiting:
            return .processing
        case .completed:
            return .completed
        case .prePurchaseError:
            return .prePurchaseError
        case .purchaseUpgradeError:
            return .purchaseUpgradeError
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
