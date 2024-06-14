@testable import WooCommerce

final class MockFavoriteProductsUseCase: FavoriteProductsUseCase {
    var markAsFavoriteCalledForProductID: Int64?

    var removeFromFavoriteCalledForProductID: Int64?

    var isFavoriteCalledForProductID: Int64?
    var isFavoriteValue = false

    var favoriteProductIDsCalled = false
    var favoriteProductIDsValue: [Int64] = []

    func markAsFavorite(productID: Int64) {
        markAsFavoriteCalledForProductID = productID
    }

    func removeFromFavorite(productID: Int64) {
        removeFromFavoriteCalledForProductID = productID
    }

    func isFavorite(productID: Int64) async -> Bool {
        isFavoriteCalledForProductID = productID
        return isFavoriteValue
    }

    func favoriteProductIDs() async -> [Int64] {
        favoriteProductIDsCalled = true
        return favoriteProductIDsValue
    }
}
