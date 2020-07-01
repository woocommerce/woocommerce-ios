
import Foundation
import Networking

import XCTest

/// Mock for `ProductReviewsRemote`.
///
final class MockProductReviewsRemote {
    private struct ResultKey: Hashable {
        let siteID: Int64
        let reviewID: Int64
    }

    /// The results to return based on the given arguments in `loadProductReview`
    private var productReviewLoadingResults = [ResultKey: Result<ProductReview, Error>]()

    /// The number of times that the `loadProductReview` method was called.
    private(set) var invocationCountOfLoadProductReview: Int = 0

    /// Set the value passed to the `completion` block if `loadProductReview()` is called.
    ///
    func whenLoadingProductReview(siteID: Int64, reviewID: Int64, thenReturn result: Result<ProductReview, Error>) {
        let key = ResultKey(siteID: siteID, reviewID: reviewID)
        productReviewLoadingResults[key] = result
    }
}

// MARK: - ProductReviewsEndpointsProviding

extension MockProductReviewsRemote: ProductReviewsEndpointsProviding {
    func loadProductReview(for siteID: Int64,
                           reviewID: Int64,
                           completion: @escaping (Result<ProductReview, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.invocationCountOfLoadProductReview += 1

            let key = ResultKey(siteID: siteID, reviewID: reviewID)
            if let result = self.productReviewLoadingResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
