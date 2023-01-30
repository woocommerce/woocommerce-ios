import Foundation
import struct Alamofire.JSONEncoding
import struct Alamofire.URLEncoding
import protocol Alamofire.ParameterEncoding

/// Protocol for `PaymentRemote` mainly used for mocking.
public protocol PaymentRemoteProtocol {
    typealias CartResponse = Dictionary<String, AnyDecodable>

    /// Loads the WPCOM plan remotely that matches the product ID.
    /// - Parameter productID: The ID of the WPCOM plan product.
    /// - Returns: The WPCOM plan that matches the given product ID.
    func loadPlan(thatMatchesID productID: Int64) async throws -> WPComPlan

    /// Loads the current WPCOM plan of a site.
    /// - Parameter siteID: ID of the site to load the current plan for.
    /// - Returns: The current WPCOM plan of the given site.
    func loadSiteCurrentPlan(siteID: Int64) async throws -> WPComSitePlan

    /// Creates a cart with the given product ID for the site ID.
    /// - Parameters:
    ///   - siteID: The ID of the site that the product is being added to.
    ///   - productID: The ID of the product to be added to the site.
    /// - Returns: The remote response from creating a cart.
    func createCart(siteID: Int64, productID: Int64) async throws

    /// Creates a cart with the given domain for the site ID.
    /// - Parameters:
    ///   - siteID: The ID of the site that the domain is being mapped to.
    ///   - domain: The domain product to purchase.
    /// - Returns: The remote response from creating a cart.
    func createCart(siteID: Int64, domain: PaidDomainSuggestion) async throws -> CartResponse
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

    public func loadSiteCurrentPlan(siteID: Int64) async throws -> WPComSitePlan {
        let path = "sites/\(siteID)/\(Path.products)"
        let request = DotcomRequest(wordpressApiVersion: .mark1_3, method: .get, path: path)
        let plansByID: [String: SiteCurrentPlanResponse] = try await enqueue(request)
        guard let currentPlan = plansByID.values.filter({ $0.isCurrentPlan == true }).first else {
            throw LoadSiteCurrentPlanError.noCurrentPlan
        }
        return .init(hasDomainCredit: currentPlan.hasDomainCredit ?? false)
    }

    public func createCart(siteID: Int64, productID: Int64) async throws {
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
        let response: CreateCartResponse = try await createCart(siteID: siteID, parameters: parameters)
        guard response.products.contains(where: { $0.productID == productID }) else {
            throw CreateCartError.productNotInCart
        }
    }

    public func createCart(siteID: Int64, domain: PaidDomainSuggestion) async throws -> CartResponse {
        let parameters: [String: Any] = [
            "products": [
                [
                    "product_id": domain.productID,
                    "volume": 1,
                    "meta": domain.name,
                    "extra": [
                        "privacy": domain.supportsPrivacy
                    ]
                ]
            ],
            // Necessary to create a persistent cart for later checkout, the default value is `true`.
            "temporary": false
        ]
        let response: CartResponse = try await createCart(siteID: siteID, parameters: parameters, encoding: JSONEncoding.default)

        // Casting the values of `[String: Any]` to fixed-size integer types like `Int64` results in `nil`.
        // https://stackoverflow.com/questions/36786883/swift-cast-any-object-to-int64-nil
        guard let productsInCart = response["products"]?.value as? [[String: Any]],
              productsInCart.contains(where: { ($0["product_id"] as? Int) == Int(domain.productID) }) else {
            throw CreateCartError.productNotInCart
        }
        return response
    }
}

private extension PaymentRemote {
    func createCart<T: Decodable>(siteID: Int64, parameters: [String: Any], encoding: ParameterEncoding = URLEncoding.default) async throws -> T {
        let path = "\(Path.cartCreation)/\(siteID)"
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters, encoding: encoding)
        return try await enqueue(request)
    }
}

/// Contains necessary data for rendering a WPCOM plan in the app.
public struct WPComPlan: Decodable, Equatable {
    public let productID: Int64
    public let name: String
    public let formattedPrice: String

    public init(productID: Int64, name: String, formattedPrice: String) {
        self.productID = productID
        self.name = name
        self.formattedPrice = formattedPrice
    }

    private enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case name = "product_name"
        case formattedPrice = "formatted_price"
    }
}

/// Contains necessary data for a site's WPCOM plan.
public struct WPComSitePlan: Equatable {
    /// Whether a site has domain credit from the WPCOM plan.
    public let hasDomainCredit: Bool

    public init(hasDomainCredit: Bool) {
        self.hasDomainCredit = hasDomainCredit
    }
}

/// Possible error cases from loading a WPCOM plan.
public enum LoadPlanError: Error {
    case noMatchingPlan
}

/// Possible error cases from loading a site's current WPCOM plan.
public enum LoadSiteCurrentPlanError: Error {
    case noCurrentPlan
}

/// Possible error cases from creating cart for a site with a WPCOM plan.
public enum CreateCartError: Error {
    case productNotInCart
}

/// Contains necessary data for handling the remote response from loading a site's current plan.
/// The fields are all optional because only the current plan has these fields.
private struct SiteCurrentPlanResponse: Decodable {
    let isCurrentPlan: Bool?
    let hasDomainCredit: Bool?

    private enum CodingKeys: String, CodingKey {
        case isCurrentPlan = "current_plan"
        case hasDomainCredit = "has_domain_credit"
    }
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
