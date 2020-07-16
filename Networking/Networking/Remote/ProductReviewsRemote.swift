import Foundation

/// Protocol for `ProductReviewsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol ProductReviewsRemoteProtocol {
    func loadProductReview(for siteID: Int64,
                           reviewID: Int64,
                           completion: @escaping (Result<ProductReview, Error>) -> Void)
}

/// Product reviews: Remote Endpoints
///
public final class ProductReviewsRemote: Remote, ProductReviewsRemoteProtocol {

    // MARK: - Product Reviews

    /// Retrieves all of the `ProductReview` available. We rely on the endpoint
    /// defaults for `sorting` and `orderby`: `date_gmt` and `asc`
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProductReviews(for siteID: Int64,
                                context: String? = nil,
                                pageNumber: Int = Default.pageNumber,
                                pageSize: Int = Default.pageSize,
                                completion: @escaping ([ProductReview]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context,
            ParameterKey.status: Default.allReviews
        ]

        let path = Path.reviews
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductReviewListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific `ProductReview`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the ProductReview.
    ///     - reviewID: Identifier of the ProductReview.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProductReview(for siteID: Int64, reviewID: Int64, completion: @escaping (Result<ProductReview, Error>) -> Void) {
        let path = "\(Path.reviews)/\(reviewID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ProductReviewMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates the status of a specific `ProductReview`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the ProductReview.
    ///     - reviewID: Identifier of the ProductReview.
    ///     - statusKey: The new status
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProductReviewStatus(for siteID: Int64, reviewID: Int64, statusKey: String, completion: @escaping (ProductReview?, Error?) -> Void) {
        let path = "\(Path.reviews)/\(reviewID)"
        let parameters = [ParameterKey.status: statusKey]
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductReviewMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension ProductReviewsRemote {
    enum Default {
        public static let pageSize: Int         = 25
        public static let pageNumber: Int       = 1
        public static let context: String       = "view"
        public static let allReviews: String    = "all"
    }

    private enum Path {
        static let reviews   = "products/reviews"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
        static let include: String    = "include"
        static let status: String     = "status"
    }
}
