#if os(iOS)

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
        let stringOfVariationIDs = variationIDs.map { String($0) }
            .joined(separator: ",")
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context,
            ParameterKey.include: variationIDs.isEmpty ? nil: stringOfVariationIDs
        ]
            .compactMapValues { $0 }

        let path = "\(Path.products)/\(productID)/variations"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
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
        static let image: String = "image"
        static let include: String    = "include"
    }
}

#endif
