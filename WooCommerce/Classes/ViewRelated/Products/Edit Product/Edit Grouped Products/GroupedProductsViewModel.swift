import Yosemite

extension Sequence where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result = [Element]()
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        return result
    }
}

final class GroupedProductsViewModel {
    // Observable list of products
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

    /// Called when a list of products is loaded (e.g. from the API).
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

    func deleteProduct(_ product: Product) {
        guard let index = groupedProducts.firstIndex(where: { $0.productID == product.productID }) else {
            productsSubject.send(.failure(.cannotDeleteProduct))
            return
        }
        groupedProducts.remove(at: index)
        groupedProductIDs.remove(at: index)
        productsSubject.send(.success(groupedProducts))
    }

    func hasUnsavedChanges() -> Bool {
        return groupedProductIDs != product.groupedProducts
    }
}

extension GroupedProductsViewModel {
    enum Error: Swift.Error {
        case unexpectedData
        case cannotDeleteProduct
    }
}
