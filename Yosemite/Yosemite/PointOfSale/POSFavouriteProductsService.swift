import Foundation
import Storage

/// Service to handle favorite products functionality for POS
///
public protocol POSFavouriteProductsServiceProtocol {
    /// Returns true if the product is marked as favorite
    func isFavorite(productID: Int64) async -> Bool

    /// Returns all favorite product IDs for the current site
    func favoriteProductIDs() async -> [Int64]

    /// Marks a product as favorite
    func markAsFavorite(productID: Int64)

    /// Removes a product from favorites
    func removeFromFavorite(productID: Int64)
}

public final class POSFavouriteProductsService: POSFavouriteProductsServiceProtocol {
    private let siteID: Int64
    private let siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol

    public init(siteID: Int64,
                siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol? = nil) {
        self.siteID = siteID
        self.siteSpecificAppSettingsStoreMethods = siteSpecificAppSettingsStoreMethods ?? SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage())
    }

    public func isFavorite(productID: Int64) async -> Bool {
        let favoriteProductIDs = siteSpecificAppSettingsStoreMethods.loadFavoriteProductIDs(siteID: siteID)
        return favoriteProductIDs.contains(productID)
    }

    public func favoriteProductIDs() async -> [Int64] {
        return siteSpecificAppSettingsStoreMethods.loadFavoriteProductIDs(siteID: siteID)
    }

    public func markAsFavorite(productID: Int64) {
        siteSpecificAppSettingsStoreMethods.setProductIDAsFavorite(productID: productID, siteID: siteID)
    }

    public func removeFromFavorite(productID: Int64) {
        siteSpecificAppSettingsStoreMethods.removeProductIDAsFavorite(productID: productID, siteID: siteID)
    }
}
