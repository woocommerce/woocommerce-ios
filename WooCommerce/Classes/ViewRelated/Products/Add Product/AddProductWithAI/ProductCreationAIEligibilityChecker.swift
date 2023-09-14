import Foundation
import Yosemite
import Experiments

/// Protocol for checking "add product using AI" eligibility for easier unit testing.
protocol ProductCreationAIEligibilityCheckerProtocol {
    /// Checks if the user is eligible for the "add product from image" feature.
    func isEligible() async throws -> Bool
}

/// Checks the eligibility for the "add product using AI" feature.
final class ProductCreationAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func isEligible() async throws -> Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }

        // Should be a new user with zero products
        guard try await checkIfStoreHasProducts(siteID: site.siteID) == false else {
            return false
        }

        return site.isWordPressComStore || site.isAIAssitantFeatureActive
    }
}

private extension ProductCreationAIEligibilityChecker {
    @MainActor
    func checkIfStoreHasProducts(siteID: Int64) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.checkIfStoreHasProducts(siteID: siteID, onCompletion: { result in
                switch result {
                case .success(let hasProducts):
                    continuation.resume(returning: hasProducts)
                case .failure(let error):
                    DDLogError("⛔️ ProductCreationAIEligibilityChecker — Error fetching products to check eligibility: \(error)")
                    continuation.resume(throwing: error)
                }
            }))
        }
    }
}
