import Foundation
import struct Alamofire.JSONEncoding
import struct Alamofire.URLEncoding
import protocol Alamofire.ParameterEncoding

/// Protocol for `PaymentRemote` mainly used for mocking.
public protocol PaymentRemoteProtocol {
    typealias CartResponse = Dictionary<String, AnyCodable>

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
    ///   - isTemporary: Whether the cart is temporary.
    ///   When the cart is being passed to a subsequent API request for checkout, this needs to be `true`.
    ///   When it's necessary to create a persistent cart for later checkout, this is set to `false`. The default value is `true`.
    /// - Returns: The remote response from creating a cart.
    func createCart(siteID: Int64, domain: PaidDomainSuggestion, isTemporary: Bool) async throws -> CartResponse

    /// Checks out the given cart using domain credit as the payment method.
    /// - Parameter cart: Cart generated from one of the `createCart` functions.
    /// - Parameter contactInfo: Contact info for the domain that needs to be validated beforehand.
    func checkoutCartWithDomainCredit(cart: CartResponse, contactInfo: DomainContactInfo) async throws
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
        let plansByID: [String: SiteCurrentPlanResponse] = try await enqueue(request, mapper: SiteCurrentPlanResponseMapper())
        guard let currentPlan = plansByID.filter({ $0.value.isCurrentPlan == true }).first else {
            throw LoadSiteCurrentPlanError.noCurrentPlan
        }

        return .init(
            id: currentPlan.key,
            hasDomainCredit: currentPlan.value.hasDomainCredit ?? false,
            expiryDate: currentPlan.value.expiryDate,
            subscribedDate: currentPlan.value.subscribedDate,
            name: currentPlan.value.name,
            slug: currentPlan.value.slug
        )
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

    public func createCart(siteID: Int64, domain: PaidDomainSuggestion, isTemporary: Bool) async throws -> CartResponse {
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
            "temporary": isTemporary
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

    public func checkoutCartWithDomainCredit(cart: CartResponse, contactInfo: DomainContactInfo) async throws {
        let path = "\(Path.cartCheckout)"
        let cartDictionary = try cart.toDictionary()
        let contactInformationDictionary = try contactInfo.toDictionary()
        let parameters: [String: Any] = [
            "cart": cartDictionary,
            "domain_details": contactInformationDictionary,
            "payment": ["payment_method": PaymentMethod.credit.rawValue]
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters, encoding: JSONEncoding.default)
        let _: DomainCreditCheckoutCartResponse = try await enqueue(request)
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
    /// ID of the WPCOM plan.
    ///
    public let id: String

    /// Whether a site has domain credit from the WPCOM plan.
    public let hasDomainCredit: Bool

    /// Plan expiry date. `Nil` if the plan does not expire.
    ///
    public let expiryDate: Date?

    /// Plan subscribe date. `Nil` if we are not subscribed to this plan.
    ///
    public let subscribedDate: Date?

    /// Plan name
    ///
    public let name: String

    /// Plan Slug
    ///
    public let slug: String

    public init(id: String = "",
                hasDomainCredit: Bool,
                expiryDate: Date? = nil,
                subscribedDate: Date? = nil,
                name: String = "",
                slug: String = "") {
        self.id = id
        self.hasDomainCredit = hasDomainCredit
        self.expiryDate = expiryDate
        self.subscribedDate = subscribedDate
        self.name = name
        self.slug = slug
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

/// Mapper: WPCom Site Plan Response Mapper.
///
private struct SiteCurrentPlanResponseMapper: Mapper {

    /// (Attempts) to convert a dictionary into a WPCom site plan entity.
    ///
    func map(response: Data) throws -> [String: SiteCurrentPlanResponse] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([String: SiteCurrentPlanResponse].self, from: response)
    }
}

/// Contains necessary data for handling the remote response from loading a site's current plan.
/// The fields are all optional because only the current plan has these fields.
private struct SiteCurrentPlanResponse: Decodable {
    let isCurrentPlan: Bool?
    let hasDomainCredit: Bool?
    let expiryDate: Date?
    let subscribedDate: Date?
    let name: String
    let slug: String

    private enum CodingKeys: String, CodingKey {
        case isCurrentPlan = "current_plan"
        case hasDomainCredit = "has_domain_credit"
        case expiryDate = "expiry"
        case subscribedDate = "subscribed_date"
        case name = "product_name"
        case slug = "product_slug"
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

private struct DomainCreditCheckoutCartResponse: Decodable {
    /// A valid receipt ID is expected in the cart checkout response with a domain credit.
    let receiptID: Int64

    private enum CodingKeys: String, CodingKey {
        case receiptID = "receipt_id"
    }
}

/// Payment method type for WPCOM cart checkout.
/// Its raw value is used as the value in the cart checkout request body.
private enum PaymentMethod: String {
    case credit = "WPCOM_Billing_WPCOM"
}

// MARK: - Constants
//
private extension PaymentRemote {
    enum Path {
        static let products = "plans"
        static let cartCreation = "me/shopping-cart"
        static let cartCheckout = "me/transactions"
    }
}
