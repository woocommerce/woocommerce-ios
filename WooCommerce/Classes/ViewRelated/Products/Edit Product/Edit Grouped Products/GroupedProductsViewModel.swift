import Yosemite

/// Contains view properties and handles actions for managing a grouped product's linked products, currently used in `GroupedProductsViewController`.
final class GroupedProductsViewModel {
    // Observable list of the latest grouped products or error on updates
    var products: Observable<Result<[Product], Error>> {
        productsSubject
    }

    // Product IDs of the latest grouped products
    private(set) var groupedProductIDs: [Int64]

    private let productsSubject: PublishSubject<Result<[Product], Error>> = PublishSubject<Result<[Product], Error>>()

    private let product: Product
    private var groupedProducts: [Product] = []

    init(product: Product) {
        self.product = product
        self.groupedProductIDs = product.groupedProducts
    }

    /// Returns whether there are unsaved changes on the grouped products.
    func hasUnsavedChanges() -> Bool {
        return groupedProductIDs != product.groupedProducts
    }
}

// MARK: Actions
extension GroupedProductsViewModel {
    /// Called when a list of products is loaded (e.g. from the API).
    /// Since a product only keeps a list of product IDs, the products are fetched separately.
    func onProductsLoaded(products: [Product]) {
        let groupedProducts = groupedProductIDs.compactMap { productID in
            products.first(where: { $0.productID == productID })
        }
        guard groupedProductIDs.count == groupedProducts.count else {
            // If the size of the product IDs and products does not match, returns an error
            productsSubject.send(.failure(.unexpectedData))
            return
        }

        self.groupedProducts = groupedProducts
        productsSubject.send(.success(groupedProducts))
    }

    /// Called when the user adds products to the grouped products.
    /// - Parameter products: a list of products that could contain the pre-selected products.
    func addProducts(_ products: [Product]) {
        let additionalProducts = products.filter { groupedProductIDs.contains($0.productID) == false }.removingDuplicates()
        guard additionalProducts.isNotEmpty else {
            return
        }
        let additionalProductIDs = additionalProducts.map { $0.productID }
        groupedProducts = groupedProducts + additionalProducts
        groupedProductIDs = groupedProductIDs + additionalProductIDs
        productsSubject.send(.success(groupedProducts))
    }

    /// Called when the user deletes a product from the grouped products.
    func deleteProduct(_ product: Product) {
        guard let index = groupedProducts.firstIndex(where: { $0.productID == product.productID }) else {
            productsSubject.send(.failure(.productDeletion))
            return
        }
        groupedProducts.remove(at: index)
        groupedProductIDs.remove(at: index)
        productsSubject.send(.success(groupedProducts))
    }
}

extension GroupedProductsViewModel {
    enum Error: Swift.Error {
        case unexpectedData
        case productDeletion
    }
}
