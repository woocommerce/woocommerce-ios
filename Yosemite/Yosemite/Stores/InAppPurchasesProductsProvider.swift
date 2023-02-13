import Foundation
import StoreKit

protocol FinishableTransaction {
    var id: String? { get }
    func finish()
}

extension SKPaymentTransaction: FinishableTransaction {
    var id: String? {
        transactionIdentifier
    }
    func finish() {
        SKPaymentQueue.default().finishTransaction(self)
    }
}

typealias ProductsRequestCompletionHandler = (([SKProduct]) -> ())?

final class InAppPurchasesProductsProvider: NSObject {
    private var productsRequest: SKProductsRequest?
    private var products: [SKProduct] = []
    private var productsRequestCompletionHandler: (([SKProduct]) -> ())?
    private var transactionContinuation: CheckedContinuation<FinishableTransaction, Error>?
    private var requestProductsContinuation: CheckedContinuation<[SKProduct], Error>?

    public func requestProducts(with identifiers: [String]) async throws -> [SKProduct] {
        return try await withCheckedThrowingContinuation { continuation in
            requestProductsContinuation = continuation

            productsRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
            productsRequest!.delegate = self
            productsRequest!.start()
        }
    }
}

extension InAppPurchasesProductsProvider: SKProductsRequestDelegate {
  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    print("Loaded list of products...")
    let products = response.products

    for p in products {
      print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
    }

      requestProductsContinuation?.resume(returning: products)
  }

  public func request(_ request: SKRequest, didFailWithError error: Error) {
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
      requestProductsContinuation?.resume(throwing: error)
  }

  private func clearRequestAndHandler() {
    productsRequest = nil
    productsRequestCompletionHandler = nil
  }
}
