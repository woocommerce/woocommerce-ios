import Yosemite

enum PrePurchaseError: Error {
    case fetchError
    case entitlementsError
    case inAppPurchasesNotSupported
    case maximumSitesUpgraded
    case userNotAllowedToUpgrade
}

enum PurchaseUpgradeError: Error {
    case inAppPurchaseFailed(WooWPComPlan, InAppPurchaseStore.Errors)
    case planActivationFailed(InAppPurchaseStore.Errors)
    case unknown

    var analyticErrorDetail: Error {
        switch self {
        case .inAppPurchaseFailed(_, let error):
            return error
        case .planActivationFailed(let error):
            return error
        default:
            return self
        }
    }
}
