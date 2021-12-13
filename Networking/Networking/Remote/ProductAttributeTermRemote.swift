import Foundation

/// Product Attribute Term: Remote Endpoints
///
public final class ProductAttributeTermRemote: Remote {

    /// Retrieves all of the `ProductAttributeTerm` available for a given attribute.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products attribute terms.
    ///     - attributeID: Identifier for the parent product attribute.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of terms to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProductAttributeTerms(for siteID: Int64,
                                          attributeID: Int64,
                                          pageNumber: Int = Default.pageNumber,
                                          pageSize: Int = Default.pageSize,
                                          completion: @escaping (Result<[ProductAttributeTerm], Error>) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize)
        ]

        let path = Path.terms(attributeID: attributeID)
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductAttributeTermListMapper(siteID: siteID)

        enqueue(request, mapper: mapper) { terms, error in
            if let error = error {
                return completion(.failure(error))
            }
            if let terms = terms {
                return completion(.success(terms))
            }
        }
    }

    /// Create a new `ProductAttributeTerm`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll add a new product attribute terms.
    ///     - name: Product attribute term name.
    ///     - attributeID: The ID for the parent product attribute.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createProductAttributeTerm(for siteID: Int64,
                                           attributeID: Int64,
                                           name: String,
                                           completion: @escaping (Result<ProductAttributeTerm, Error>) -> Void) {
        let parameters = [
            ParameterKey.name: name
        ]

        let path = Path.terms(attributeID: attributeID)
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductAttributeTermMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants
public extension ProductAttributeTermRemote {
    enum Default {
        public static let pageSize: Int = 25
        public static let pageNumber: Int = 1
    }

    private enum Path {
        static func terms(attributeID: Int64) -> String {
            "products/attributes/\(attributeID)/terms"
        }
    }

    private enum ParameterKey {
        static let page: String = "page"
        static let perPage: String = "per_page"
        static let name: String = "name"
    }
}
