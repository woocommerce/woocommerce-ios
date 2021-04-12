import Foundation


// MARK: - Coupon

/// Represents a Coupon entity: https://woocommerce.github.io/woocommerce-rest-api-docs/?shell#coupons
///
public struct Coupon {
    /// `siteId` should be set on a copy in the Mapper as it's not returned by the API.
    /// Using a default here gives us the benefit of synthesised codable conformance.
    /// `private(set) var` is required so that `siteId` will still be on the synthesised`init` which `copy()` uses
    private(set) var siteId: Int64 = 0
    let couponId: Int64
    /// The coupon code for use at checkout
    let code: String
    /// Discount provided by the coupon, used whether the `discountType` is a percentage or fixed amount type.
    let amount: String
    /// Date the coupon was created, in GMT (UTC)
    let dateCreated: Date
    /// Date the coupon was modified (or created), in GMT (UTC)
    let dateModified: Date
    /// Determines the type of discount that will be applied. Options: `.percent` `.fixedCart` and `.fixedProduct`
    let discountType: DiscountType
    let description: String
    /// Date the coupon will expire, in GMT (UTC)
    let dateExpires: Date?
    /// Total number of times this coupon has been used, by all customers
    let usageCount: Int64
    /// Whether the coupon can only be used alone (`true`) or in conjunction with other coupons (`false`)
    let individualUse: Bool
    /// Product IDs of products this coupon can be used against
    let productIds: [Int64]
    /// Product IDs of products this coupon cannot be used against
    let excludedProductIds: [Int64]
    /// Total number of times this coupon can be used
    let usageLimit: Int64?
    /// Number of times this coupon be used per customer
    let usageLimitPerUser: Int64?
    /// Maximum number of items which the coupon can be applied to in the cart
    let limitUsageToXItems: Int64?
    /// Whether the coupon should provide free shipping
    let freeShipping: Bool
    /// Categories which this coupon applies to
    let productCategories: [Int64]
    /// Categories which this coupon cannot be used on
    let excludedProductCategories: [Int64]
    /// If `true`, this coupon will not be applied to items that have sale prices
    let excludeSaleItems: Bool
    /// Minimum order amount that needs to be in the cart before coupon applies
    let minimumAmount: String
    /// Maximum order amount allowed when using the coupon
    let maximumAmount: String
    /// Email addresses of customers who are allowed to use this coupon, which may include * as wildcard
    let emailRestrictions: [String]
    /// Email addresses of customers who have used this coupon
    let usedBy: [String]

    public enum DiscountType: String {
        case percent = "percent"
        case fixedCart = "fixed_cart"
        case fixedProduct = "fixed_product"
    }
}


// MARK: - Codable Conformance

/// Defines all of the Coupon CodingKeys
/// The model is intended to be decoded with`JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase`
/// so any specific `CodingKeys` provided here should be in camel case.
extension Coupon: Codable {
    enum CodingKeys: String, CodingKey {
        case couponId = "id"
        case code
        case amount
        case dateCreated = "dateCreatedGmt"
        case dateModified = "dateModifiedGmt"
        case discountType
        case description
        case dateExpires = "dateExpiresGmt"
        case usageCount
        case individualUse
        case productIds
        case excludedProductIds
        case usageLimit
        case usageLimitPerUser
        case limitUsageToXItems
        case freeShipping
        case productCategories
        case excludedProductCategories
        case excludeSaleItems
        case minimumAmount
        case maximumAmount
        case emailRestrictions
        case usedBy
    }
}

extension Coupon.DiscountType: Codable {}


// MARK: - Other Conformances

extension Coupon: GeneratedCopiable, GeneratedFakeable, Equatable {}

extension Coupon.DiscountType: GeneratedCopiable, GeneratedFakeable, Equatable {}
