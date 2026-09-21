import Foundation
import Yosemite

/// Tells whether a bundle holds a product which cannot be added to an order.
///
/// A bundle is not itself a subscription or a bookable product, so nothing stops a merchant selecting one;
/// the unsupported product is inside it. The bundle's metadata carries no product type, so the children have
/// to be resolved to answer the question.
///
struct UnsupportedBundledProductChecker {
    /// `unknown` is deliberately distinct from `supported`: letting a bundle through because a request failed
    /// is how an unsupported product ends up on an order in the first place.
    ///
    enum Result: Equatable {
        case supported
        case unsupported(ProductRestriction)
        case unknown
    }

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    @MainActor
    func check(bundle: Product) async -> Result {
        guard bundle.bundledItems.isNotEmpty else {
            return .supported
        }

        let products: [Product]
        do {
            products = try await retrieveBundledProducts(for: bundle)
        } catch {
            DDLogError("⛔️ Error loading bundled products while checking a bundle for an order: \(error)")
            return .unknown
        }

        // A restricted child is the answer even when a sibling could not be resolved: the bundle is
        // unsellable either way, and naming the reason is more use than asking the merchant to retry.
        if let restriction = products.compactMap({ ProductRestriction.restriction(for: $0) }).first {
            return .unsupported(restriction)
        }

        return products.count < bundle.bundledItems.count ? .unknown : .supported
    }
}

private extension UnsupportedBundledProductChecker {
    @MainActor
    func retrieveBundledProducts(for bundle: Product) async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.retrieveProductsIfNeeded(siteID: bundle.siteID,
                                                              productIDs: bundle.bundledItems.map { $0.productID }) { result in
                continuation.resume(with: result)
            })
        }
    }
}
