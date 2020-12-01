import Foundation

public struct MockProductRemote: ProductsRemoteProtocol {

    private let objectGraph: MockObjectGraph

    public init(objectGraph: MockObjectGraph) {
        self.objectGraph = objectGraph
    }

    public func addProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void) {
        preconditionFailure("Not implemented")
    }

    public func deleteProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void) {
        preconditionFailure("Not implemented")
    }

    public func loadProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void) {
    }

    public func loadAllProducts(
        for siteID: Int64,
        context: String?,
        pageNumber: Int,
        pageSize: Int,
        stockStatus: ProductStockStatus?,
        productStatus: ProductStatus?,
        productType: ProductType?,
        orderBy: ProductsRemote.OrderKey,
        order: ProductsRemote.Order,
        excludedProductIDs: [Int64],
        completion: @escaping (Result<[Product], Error>) -> Void
    ) {
        completion(.success(objectGraph.products(forSiteId: siteID)))
    }

    public func loadProducts(
        for siteID: Int64,
        by productIDs: [Int64],
        pageNumber: Int,
        pageSize: Int,
        completion: @escaping (Result<[Product], Error>) -> Void
    ) {
        completion(.success(objectGraph.products(forSiteId: siteID, productIds: productIDs)))
    }

    public func searchProducts(
        for siteID: Int64,
        keyword: String,
        pageNumber: Int,
        pageSize: Int,
        excludedProductIDs: [Int64],
        completion: @escaping ([Product]?, Error?) -> Void
    ) {
        completion([], nil)
    }

    public func searchSku(for siteID: Int64, sku: String, completion: @escaping (String?, Error?) -> Void) {
        preconditionFailure("Not implemented")
    }

    public func updateProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void) {
        preconditionFailure("Not implemented")
    }
}
