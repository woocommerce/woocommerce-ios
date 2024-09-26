import Foundation
import Yosemite

protocol FavoriteProductsUseCase {
    func markAsFavorite(productID: Int64)

    func removeFromFavorite(productID: Int64)

    func isFavorite(productID: Int64) async -> Bool

    func favoriteProductIDs() async -> [Int64]
}

/// Used for marking/removing products as favorite
///
struct DefaultFavoriteProductsUseCase: FavoriteProductsUseCase {
    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
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

    @MainActor
    func isFavorite(productID: Int64) async -> Bool {
        return await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadFavoriteProductIDs(siteID: siteID, onCompletion: { savedFavProductIDs in
                continuation.resume(returning: savedFavProductIDs.contains(where: { $0 == productID }))
            }))
        }
    }

    @MainActor
    func favoriteProductIDs() async -> [Int64] {
        return await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadFavoriteProductIDs(siteID: siteID, onCompletion: { savedFavProductIDs in
                continuation.resume(returning: savedFavProductIDs)
            }))
        }
    }
}
