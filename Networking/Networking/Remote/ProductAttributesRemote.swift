import Foundation

/// Product Attributes: Remote Endpoints for fetching global product attributes.
///
public final class ProductAttributesRemote: Remote {

    // MARK: - Product Attributes

    /// Retrieves all of the global`ProductAttribute` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products attributes.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProductAttributes(for siteID: Int64,
                                         completion: @escaping (Result<[ProductAttribute], Error>) -> Void) {

        let path = Path.attributes
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path)

        let mapper = ProductAttributeListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Create a new `ProductAttribute`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll add a new product attribute.
    ///     - name: Attribute name.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createProductAttribute(for siteID: Int64,
                                       name: String,
                                       completion: @escaping (Result<ProductAttribute, Error>) -> Void) {
        let parameters = [
            ParameterKey.name: name,
            ParameterKey.slug: name,
            ParameterKey.type: Default.type,
            ParameterKey.orderBy: Default.orderBy,
            ParameterKey.hasArchives: Default.hasArchives
        ]

        let path = Path.attributes
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductAttributeMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Update a `ProductAttribute`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll update the product attribute.
    ///     - productAttributeID: ID of the Product Attribute that will be updated.
    ///     - name: Attribute name.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProductAttribute(for siteID: Int64,
                                       productAttributeID: Int64,
                                       name: String,
                                       completion: @escaping (Result<ProductAttribute, Error>) -> Void) {
        let parameters = [
            ParameterKey.attributeID: String(productAttributeID),
            ParameterKey.name: name,
            ParameterKey.slug: name,
            ParameterKey.type: Default.type,
            ParameterKey.orderBy: Default.orderBy,
            ParameterKey.hasArchives: Default.hasArchives
        ]

        let path = Path.attributes + "/\(productAttributeID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .put, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductAttributeMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Delete a `ProductAttribute`.  This also will delete all terms from the selected attribute.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll delete the product attribute.
    ///     - productAttributeID: ID of the Product Attribute that will be deleted.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func deleteProductAttribute(for siteID: Int64,
                                       productAttributeID: Int64,
                                       completion: @escaping (Result<ProductAttribute, Error>) -> Void) {

        let path = Path.attributes + "/\(productAttributeID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .put, siteID: siteID, path: path)
        let mapper = ProductAttributeMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension ProductAttributesRemote {

    enum Default {
        public static let type: String = "select"
        public static let orderBy: String = "menu_order"
        public static let hasArchives: String = "false"
    }

    private enum Path {
        static let attributes = "products/attributes"
    }

    private enum ParameterKey {
        static let attributeID: String = "id"
        static let name: String = "name"
        static let slug: String = "slug"
        static let type: String = "type"
        static let orderBy: String = "order_by"
        static let hasArchives: String = "has_archives"
    }
}
