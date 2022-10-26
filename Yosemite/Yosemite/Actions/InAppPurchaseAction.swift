import Foundation
import StoreKit

public enum InAppPurchaseAction: Action {
    case loadProducts(completion: (Result<[StoreKit.Product], Error>) -> Void)
    case purchaseProduct(siteID: Int64, product: StoreKit.Product, completion: (Result<StoreKit.Product.PurchaseResult, Error>) -> Void)
    case handleCompletedTransaction(_ result: VerificationResult<StoreKit.Transaction>, completion: (Result<(), Error>) -> Void)
}
