import Foundation

/// Protocol for `ProductVariationsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol ProductVariationsRemoteProtocol {
    func updateProductVariation(productVariation: ProductVariation, completion: @escaping (Result<ProductVariation, Error>) -> Void)
    func loadAllProductVariations(for siteID: Int64,
                                  productID: Int64,
                                  context: String?,
                                  pageNumber: Int,
                                  pageSize: Int,
                                  completion: @escaping ([ProductVariation]?, Error?) -> Void)
    func loadProductVariation(for siteID: Int64, productID: Int64, variationID: Int64, completion: @escaping (Result<ProductVariation, Error>) -> Void)
}

/// ProductVariation: Remote Endpoints
///
public class ProductVariationsRemote: Remote, ProductVariationsRemoteProtocol {

    /// Retrieves all of the `ProductVariation`s available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote product variations.
    ///     - productID: Product for which we'll fetch remote product variations.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of product variations to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProductVariations(for siteID: Int64,
                                         productID: Int64,
                                         context: String? = nil,
                                         pageNumber: Int = Default.pageNumber,
                                         pageSize: Int = Default.pageSize,
                                         completion: @escaping ([ProductVariation]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context
        ]

        let path = "\(Path.products)/\(productID)/variations"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductVariationListMapper(siteID: siteID, productID: productID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific `ProductVariation`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the ProductVariation.
    ///     - productID: Identifier of the Product.
    ///     - variationID: Identifier of the Variation.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProductVariation(for siteID: Int64, productID: Int64, variationID: Int64, completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        let path = "\(Path.products)/\(productID)/variations/\(variationID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ProductVariationMapper(siteID: siteID, productID: productID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates a specific `ProductVariation`.
    ///
    /// - Parameters:
    ///     - productVariation: the ProductVariation to update remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProductVariation(productVariation: ProductVariation, completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        do {
            let parameters = try productVariation.toDictionary()
            let productID = productVariation.productID
            let siteID = productVariation.siteID
            let path = "\(Path.products)/\(productID)/variations/\(productVariation.productVariationID)"
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
            let mapper = ProductVariationMapper(siteID: siteID, productID: productID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}


// MARK: - Constants
//
public extension ProductVariationsRemote {
    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = 1
        public static let context: String = "view"
    }

    private enum Path {
        static let products   = "products"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}
