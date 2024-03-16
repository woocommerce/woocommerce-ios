import Foundation

struct FavoriteProductsUseCase {
    private let siteID: Int64
    private let userDefaults: UserDefaults

    private var idAsString: String {
        "\(siteID)"
    }

    private var productIdDict: [String: [Int64]]? {
        userDefaults[.favoriteProductIDs] as? [String: [Int64]]
    }

    init(siteID: Int64,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.userDefaults = userDefaults
    }

    func markAsFavorite(productID: Int64) {
        if var productIdDict = productIdDict {
            let existingFavProductIDs = productIdDict[idAsString] ?? []
            productIdDict[idAsString] = Array(Set(existingFavProductIDs + [productID])).suffix(Constants.favoriteProductsMaxLimit)
            userDefaults[.favoriteProductIDs] = productIdDict
        } else {
            userDefaults[.favoriteProductIDs] = [idAsString: [productID]]
        }
    }

    func removeFromFavorite(productID: Int64) {
        guard var productIdDict = productIdDict else {
            return
        }

        guard var savedFavProductIDs = productIdDict[idAsString],
              let indexOfFavProductToBeRemoved = savedFavProductIDs.firstIndex(of: productID) else {
            return
        }

        savedFavProductIDs.remove(at: indexOfFavProductToBeRemoved)
        productIdDict[idAsString] = savedFavProductIDs

        userDefaults[.favoriteProductIDs] = productIdDict
    }

    func isFavorite(productID: Int64) -> Bool {
        guard let productIdDict = productIdDict,
              let savedFavProductIDs = productIdDict[idAsString] else {
            return false
        }

        return savedFavProductIDs.contains(where: { $0 == productID })
    }

    func favoriteProductIDs() -> [Int64]? {
        guard let productIdDict = productIdDict,
              let savedFavProductIDs = productIdDict[idAsString] else {
            return nil
        }
        return savedFavProductIDs
    }
}

private extension FavoriteProductsUseCase {
    enum Constants {
        static let favoriteProductsMaxLimit = 10
    }
}

extension UserDefaults {
    /// Expose value for `favoriteProductIDs` to be observable through KVO.
    @objc var favoriteProductIDs: [String: Any]? {
        get {
            dictionary(forKey: Key.favoriteProductIDs.rawValue)
        }
        set {
            set(newValue, forKey: Key.favoriteProductIDs.rawValue)
        }
    }
}
