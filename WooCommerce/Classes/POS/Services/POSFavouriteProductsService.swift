import Foundation
import Yosemite
import Experiments

/// Service to handle favorite products functionality for POS
///
protocol POSFavouriteProductsServiceProtocol {
    /// Returns true if the product is marked as favorite
    @MainActor
    func isFavorite(productID: Int64) async -> Bool

    /// Returns all favorite product IDs for the current site
    @MainActor
    func favoriteProductIDs() async -> [Int64]

    /// Marks a product as favorite
    @MainActor
    func markAsFavorite(productID: Int64)

    /// Removes a product from favorites
    @MainActor
    func removeFromFavorite(productID: Int64)
}

final class POSFavouriteProductsService: POSFavouriteProductsServiceProtocol {
    private let siteID: Int64
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    @MainActor
    func isFavorite(productID: Int64) async -> Bool {
        return await withCheckedContinuation { @MainActor continuation in
            stores.dispatch(AppSettingsAction.loadFavoriteProductIDs(siteID: siteID, onCompletion: { savedFavProductIDs in
                continuation.resume(returning: savedFavProductIDs.contains(where: { $0 == productID }))
            }))
        }
    }

    @MainActor
    func favoriteProductIDs() async -> [Int64] {
        guard featureFlagService.isFeatureFlagEnabled(.favoriteProducts) else {
            return []
        }
        return await withCheckedContinuation { @MainActor continuation in
            stores.dispatch(AppSettingsAction.loadFavoriteProductIDs(siteID: siteID, onCompletion: { savedFavProductIDs in
                continuation.resume(returning: savedFavProductIDs)
            }))
        }
    }

    @MainActor
    func markAsFavorite(productID: Int64) {
        let action = AppSettingsAction.setProductIDAsFavorite(productID: productID, siteID: siteID)
        stores.dispatch(action)
    }

    @MainActor
    func removeFromFavorite(productID: Int64) {
        let action = AppSettingsAction.removeProductIDAsFavorite(productID: productID, siteID: siteID)
        stores.dispatch(action)
    }
}
