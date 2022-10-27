import Foundation
import StoreKit

public enum InAppPurchaseAction: Action {
    case loadProducts(completion: (Result<[StoreKit.Product], Error>) -> Void)
    case purchaseProduct(siteID: Int64, productID: String, completion: (Result<StoreKit.Product.PurchaseResult, Error>) -> Void)
    case userIsEntitledToProduct(productID: String, completion: (Result<Bool, Error>) -> Void)
    case inAppPurchasesAreSupported(completion: (Bool) -> Void)
    case retryWPComSyncForPurchasedProduct(productID: String, completion: (Result<(), Error>) -> Void)
}
