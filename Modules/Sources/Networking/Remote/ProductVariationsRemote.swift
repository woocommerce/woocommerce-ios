import Foundation

/// Protocol for `ProductVariationsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol ProductVariationsRemoteProtocol {
    func loadAllProductVariations(for siteID: Int64,
                                  productID: Int64,
                                  variationIDs: [Int64],
                                  context: String?,
                                  pageNumber: Int,
                                  pageSize: Int,
                                  completion: @escaping ([ProductVariation]?, Error?) -> Void)
    func loadVariationsForPointOfSale(for siteID: Int64,
                                      parentProductID: Int64,
                                      pageNumber: Int,
                                      posProductsOnly: Bool) async throws -> PagedItems<POSProductVariation>
    func loadProductVariation(for siteID: Int64, productID: Int64, variationID: Int64, completion: @escaping (Result<ProductVariation, Error>) -> Void)
    func createProductVariation(for siteID: Int64,
                                productID: Int64,
                                newVariation: CreateProductVariation,
                                completion: @escaping (Result<ProductVariation, Error>) -> Void)
    func createProductVariations(siteID: Int64,
                                 productID: Int64,
                                 productVariations: [CreateProductVariation],
                                 completion: @escaping (Result<[ProductVariation], Error>) -> Void)
    func updateProductVariation(productVariation: ProductVariation, completion: @escaping (Result<ProductVariation, Error>) -> Void)
    func updateProductVariationImage(siteID: Int64,
                                     productID: Int64,
                                     variationID: Int64,
                                     image: ProductImage,
                                     completion: @escaping (Result<ProductVariation, Error>) -> Void)
    func updateProductVariations(siteID: Int64,
                                 productID: Int64,
                                 productVariations: [ProductVariation],
                                 completion: @escaping (Result<[ProductVariation], Error>) -> Void)
    func deleteProductVariation(siteID: Int64, productID: Int64, variationID: Int64, completion: @escaping (Result<ProductVariation, Error>) -> Void)
}


/// ProductVariation: Remote Endpoints
///
public class ProductVariationsRemote: Remote, ProductVariationsRemoteProtocol {

    /// Retrieves all of the `ProductVariation`s available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote product variations.
    ///     - productID: Product for which we'll fetch remote product variations.
    ///     - variationIDs: A list of variation IDs to fetch from the product. If the value is empty, all variations are returned.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of product variations to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProductVariations(for siteID: Int64,
                                         productID: Int64,
                                         variationIDs: [Int64],
                                         context: String? = nil,
                                         pageNumber: Int = Default.pageNumber,
                                         pageSize: Int = Default.pageSize,
                                         completion: @escaping ([ProductVariation]?, Error?) -> Void) {
        let request = productVariationsRequest(for: siteID,
                                               productID: productID,
                                               variationIDs: variationIDs,
                                               context: context,
                                               pageNumber: pageNumber,
                                               pageSize: pageSize)
        let mapper = ProductVariationListMapper(siteID: siteID, productID: productID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the `ProductVariation`s available in POS.
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch remote product variations.
    ///   - parentProductID: Product for which we'll fetch remote product variations.
    ///   - pageNumber: Number of page that should be retrieved.
    /// - Returns: Variations for the provided parent product.
    public func loadVariationsForPointOfSale(for siteID: Int64,
                                             parentProductID: Int64,
                                             pageNumber: Int = Default.pageNumber,
                                             posProductsOnly: Bool = false) async throws -> PagedItems<POSProductVariation> {
        let request = productVariationsRequest(for: siteID,
                                               productID: parentProductID,
                                               variationIDs: [],
                                               downloadable: false,
                                               status: .published,
                                               orderBy: .menuOrder,
                                               order: .ascending,
                                               fields: POSProductVariation.requestFields,
                                               context: nil,
                                               pageNumber: pageNumber,
                                               pageSize: POSConstants.variationsPerPage,
                                               posProductsOnly: posProductsOnly)
        // N.B. POS is only available for WC 9.6 and later.
        // `parent_id` was added in WC 8.3, so we don't need to pass the parent product ID to the decoder.
        // https://github.com/woocommerce/woocommerce/pull/40606
        // This isn't safe to do in the endpoints for the main app, as older sites won't have `parent_id`.
        let mapper = ListMapper<POSProductVariation>(siteID: siteID)

        let (variations, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)
        return createPagedItems(items: variations, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    private func productVariationsRequest(for siteID: Int64,
                                          productID: Int64,
                                          variationIDs: [Int64],
                                          downloadable: Bool? = nil,
                                          status: ProductStatus? = nil,
                                          orderBy: OrderByField? = nil,
                                          order: OrderDirection? = nil,
                                          fields: [String] = [],
                                          context: String?,
                                          pageNumber: Int,
                                          pageSize: Int,
                                          posProductsOnly: Bool = false) -> JetpackRequest {
        let stringOfVariationIDs = variationIDs.map { String($0) }
            .joined(separator: ",")
        let stringOfRequiredFields = fields.joined(separator: ",")
        var parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.downloadable: downloadable.map { String($0) },
            ParameterKey.contextKey: context ?? Default.context,
            ParameterKey.fields: fields.isEmpty ? nil : stringOfRequiredFields,
            ParameterKey.include: variationIDs.isEmpty ? nil: stringOfVariationIDs,
            ParameterKey.status: status?.rawValue,
            ParameterKey.orderBy: orderBy?.rawValue,
            ParameterKey.order: order?.rawValue,
            ParameterKey.posProductsOnly: String(posProductsOnly)
        ]
            .compactMapValues { $0 }

        let path = "\(Path.products)/\(productID)/variations"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        return request
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
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = ProductVariationMapper(siteID: siteID, productID: productID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Creates a new `ProductVariation`.
    ///
    /// - Parameters:
    ///     - siteID: Site which will hosts the ProductVariations.
    ///     - productID: Identifier of the Product.
    ///     - variation: the CreateProductVariation sent for creating a ProductVariation remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createProductVariation(for siteID: Int64,
                                        productID: Int64,
                                        newVariation: CreateProductVariation,
                                        completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        do {
            let parameters = try newVariation.toDictionary()

            let path = "\(Path.products)/\(productID)/variations"
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = ProductVariationMapper(siteID: siteID, productID: productID)
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Creates the provided `ProductVariations`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the ProductVariations.
    ///     - productID: Identifier of the Product.
    ///     - productVariations: the ProductVariations to created remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createProductVariations(siteID: Int64,
                                        productID: Int64,
                                        productVariations: [CreateProductVariation],
                                        completion: @escaping (Result<[ProductVariation], Error>) -> Void) {

        do {
            let parameters = try productVariations.map { try $0.toDictionary() }
            let path = "\(Path.products)/\(productID)/variations/batch"
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: ["create": parameters],
                                         availableAsRESTRequest: true)
            let mapper = ProductVariationsBulkCreateMapper(siteID: siteID, productID: productID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
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
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = ProductVariationMapper(siteID: siteID, productID: productID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Updates the image of a specific `ProductVariation`.
    ///
    /// - Parameters:
    ///   - siteID: Site which will hosts the ProductVariation.
    ///   - productID: Identifier of the Product.
    ///   - variationID: Identifier of the ProductVariation.
    ///   - image: Image to be set to the ProductVariation.
    ///   - completion: Closure to be executed upon completion.
    public func updateProductVariationImage(siteID: Int64,
                                            productID: Int64,
                                            variationID: Int64,
                                            image: ProductImage,
                                            completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        do {
            let parameters = try ([ParameterKey.image: image]).toDictionary()
            let path = "\(Path.products)/\(productID)/variations/\(variationID)"
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = ProductVariationMapper(siteID: siteID, productID: productID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Updates the provided `ProductVariations`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the ProductVariations.
    ///     - productID: Identifier of the Product.
    ///     - productVariations: the ProductVariations to update remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProductVariations(siteID: Int64,
                                        productID: Int64,
                                        productVariations: [ProductVariation],
                                        completion: @escaping (Result<[ProductVariation], Error>) -> Void) {

        do {
            let parameters = try productVariations.map { try $0.toDictionary() }
            let path = "\(Path.products)/\(productID)/variations/batch"
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: ["update": parameters],
                                         availableAsRESTRequest: true)
            let mapper = ProductVariationsBulkUpdateMapper(siteID: siteID, productID: productID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Deletes a specific `ProductVariation`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the ProductVariation.
    ///     - productID: Identifier of the Product.
    ///     - variationID: Identifier of the Variation.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func deleteProductVariation(siteID: Int64, productID: Int64, variationID: Int64, completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        let path = "\(Path.products)/\(productID)/variations/\(variationID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .delete,
                                     siteID: siteID,
                                     path: path,
                                     parameters: ["force": true],
                                     availableAsRESTRequest: true)
        let mapper = ProductVariationMapper(siteID: siteID, productID: productID)

        enqueue(request, mapper: mapper, completion: completion)
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
        static let fields: String     = "_fields"
        static let image: String = "image"
        static let include: String    = "include"
        static let downloadable: String = "downloadable"
        static let status: String = "status"
        static let orderBy: String    = "orderby"
        static let order: String      = "order"
        static let posProductsOnly: String = "pos_products_only"
    }

    enum OrderByField: String {
        case date
        case menuOrder = "menu_order"
    }

    enum OrderDirection: String {
        case ascending = "asc"
        case descending = "desc"
    }

}

private extension ProductVariationsRemote {
    enum POSConstants {
        static let variationsPerPage: Int = 25
    }
}
