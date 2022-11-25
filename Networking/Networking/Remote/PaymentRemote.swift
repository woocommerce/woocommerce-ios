import Foundation

/// Protocol for `PaymentRemote` mainly used for mocking.
public protocol PaymentRemoteProtocol {
    /// Loads the WPCOM plan remotely that matches the product ID.
    /// - Parameter productID: The ID of the WPCOM plan product.
    /// - Returns: The WPCOM plan that matches the given product ID.
    func loadPlan(thatMatchesID productID: Int64) async throws -> WPComPlan

    /// Creates a cart with the given product ID for the site ID.
    /// - Parameters:
    ///   - siteID: The ID of the site that the product is being added to.
    ///   - productID: The ID of the product to be added to the site.
    /// - Returns: The remote response from creating a cart.
    func createCart(siteID: Int64, productID: Int64) async throws
}

/// WPCOM Payment Endpoints
///
public class PaymentRemote: Remote, PaymentRemoteProtocol {
    public func loadPlan(thatMatchesID productID: Int64) async throws -> WPComPlan {
        let path = Path.products
        let request = DotcomRequest(wordpressApiVersion: .mark1_5, method: .get, path: path)
        let plans: [WPComPlan] = try await enqueue(request)
        guard let plan = plans.first(where: { $0.productID == productID }) else {
            throw LoadPlanError.noMatchingPlan
        }
        return plan
    }

    public func createCart(siteID: Int64, productID: Int64) async throws {
        let path = "\(Path.cartCreation)/\(siteID)"

        let parameters: [String: Any] = [
            "products": [
                [
                    "product_id": productID,
                    "volume": 1
                ]
            ],
            // Necessary to create a persistent cart for later checkout, the default value is `true`.
            "temporary": false
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        let response: CreateCartResponse = try await enqueue(request)
        guard response.products.contains(where: { $0.productID == productID }) else {
            throw CreateCartError.productNotInCart
        }
    }
}

/// Contains necessary data for rendering a WPCOM plan in the app.
public struct WPComPlan: Decodable, Equatable {
    public let productID: Int64
    public let name: String
    public let formattedPrice: String

    private enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case name = "product_name"
        case formattedPrice = "formatted_price"
    }
}

/// Possible error cases from loading a WPCOM plan.
public enum LoadPlanError: Error {
    case noMatchingPlan
}

/// Possible error cases from creating cart for a site with a WPCOM plan.
public enum CreateCartError: Error {
    case productNotInCart
}

/// Contains necessary data for handling the remote response from creating a cart.
private struct CreateCartResponse: Decodable {
    let products: [Product]

    private enum CodingKeys: String, CodingKey {
        case products
    }
}

private extension CreateCartResponse {
    /// Describes a product in a cart.
    struct Product: Decodable {
        let productID: Int64

        private enum CodingKeys: String, CodingKey {
            case productID = "product_id"
        }
    }
}

// MARK: - Constants
//
private extension PaymentRemote {
    enum Path {
        static let products = "plans"
        static let cartCreation = "me/shopping-cart"
    }
}
