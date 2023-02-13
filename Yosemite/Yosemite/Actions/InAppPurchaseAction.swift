import Foundation
import StoreKit

public enum InAppPurchaseAction: Action {
    case loadProducts(completion: (Result<[WPComPlanProduct], Error>) -> Void)
    case purchaseProduct(siteID: Int64, productID: String, completion: (Result<InAppPurchaseResult, Error>) -> Void)
    case userIsEntitledToProduct(productID: String, completion: (Result<Bool, Error>) -> Void)
    case inAppPurchasesAreSupported(completion: (Bool) -> Void)
    case retryWPComSyncForPurchasedProduct(productID: String, completion: (Result<(), Error>) -> Void)
}
