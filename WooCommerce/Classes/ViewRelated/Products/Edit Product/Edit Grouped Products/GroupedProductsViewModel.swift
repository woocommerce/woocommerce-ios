import Yosemite

/// Contains view properties and handles actions for managing a grouped product's linked products, currently used in `GroupedProductsViewController`.
final class GroupedProductsViewModel {
    // Observable list of the latest grouped product IDs or error on updates
    var productIDs: Observable<Result<[Int64], Error>> {
        productIDsSubject
    }

    private let productIDsSubject: PublishSubject<Result<[Int64], Error>> = PublishSubject<Result<[Int64], Error>>()

    // Product IDs of the latest grouped products
    private(set) var groupedProductIDs: [Int64]

    private let product: Product

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
    /// Called when the user adds products to the grouped products.
    /// - Parameter products: a list of products to add to a grouped product.
    func addProducts(_ productIDs: [Int64]) {
        groupedProductIDs = (groupedProductIDs + productIDs).removingDuplicates()
        productIDsSubject.send(.success(groupedProductIDs))
    }

    /// Called when the user deletes a product from the grouped products.
    func deleteProduct(_ product: Product) {
        guard let index = groupedProductIDs.firstIndex(where: { $0 == product.productID }) else {
            productIDsSubject.send(.failure(.productDeletion))
            return
        }
        groupedProductIDs.remove(at: index)
        productIDsSubject.send(.success(groupedProductIDs))
    }
}

extension GroupedProductsViewModel {
    enum Error: Swift.Error {
        case unexpectedData
        case productDeletion
    }
}
