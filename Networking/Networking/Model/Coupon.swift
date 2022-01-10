import Foundation
import Codegen

// MARK: - Coupon

/// Represents a Coupon entity: https://woocommerce.github.io/woocommerce-rest-api-docs/?shell#coupons
///
public struct Coupon {
    /// `siteID` should be set on a copy in the Mapper as it's not returned by the API.
    /// Using a default here gives us the benefit of synthesised codable conformance.
    /// `private(set) public var` is required so that `siteID` will still be on the synthesised`init` which `copy()` uses
    private(set) public var siteID: Int64 = 0

    public let couponID: Int64

    /// The coupon code for use at checkout
    public let code: String

    /// Discount provided by the coupon, used whether the `discountType` is a percentage or fixed amount type.
    public let amount: String

    /// Date the coupon was created, in GMT (UTC)
    public let dateCreated: Date

    /// Date the coupon was modified (or created), in GMT (UTC)
    public let dateModified: Date

    /// Determines the type of discount that will be applied. Options: `.percent` `.fixedCart` and `.fixedProduct`
    public var discountType: DiscountType {
        if let type = mappedDiscountType {
            return type
        } else {
            // Returns default value for fallback case to avoid working with optionals.
            // Since `CouponListMapper` filters out nil `mappedDiscountType`,
            // this case is unlikely to happen.
            return .fixedCart
        }
    }

    /// Discount type if matched with any of the ones supported by Core.
    /// Returns nil if other types are found.
    /// Used to filter only coupons with default types, so internal to this module only.
    ///
    internal let mappedDiscountType: DiscountType?

    public let description: String

    /// Date the coupon will expire, in GMT (UTC)
    public let dateExpires: Date?

    /// Total number of times this coupon has been used, by all customers
    public let usageCount: Int64

    /// Whether the coupon can only be used alone (`true`) or in conjunction with other coupons (`false`)
    public let individualUse: Bool

    /// Product IDs of products this coupon can be used against
    public let productIds: [Int64]

    /// Product IDs of products this coupon cannot be used against
    public let excludedProductIds: [Int64]

    /// Total number of times this coupon can be used
    public let usageLimit: Int64?

    /// Number of times this coupon be used per customer
    public let usageLimitPerUser: Int64?

    /// Maximum number of items which the coupon can be applied to in the cart
    public let limitUsageToXItems: Int64?

    /// Whether the coupon should provide free shipping
    public let freeShipping: Bool

    /// Categories which this coupon applies to
    public let productCategories: [Int64]

    /// Categories which this coupon cannot be used on
    public let excludedProductCategories: [Int64]

    /// If `true`, this coupon will not be applied to items that have sale prices
    public let excludeSaleItems: Bool

    /// Minimum order amount that needs to be in the cart before coupon applies
    public let minimumAmount: String

    /// Maximum order amount allowed when using the coupon
    public let maximumAmount: String

    /// Email addresses of customers who are allowed to use this coupon, which may include * as wildcard
    public let emailRestrictions: [String]

    /// Email addresses of customers who have used this coupon
    public let usedBy: [String]

    /// Discount types supported by Core.
    /// There are other types supported by other plugins, but those are not supported for now.
    ///
    public enum DiscountType: String {
        case percent = "percent"
        case fixedCart = "fixed_cart"
        case fixedProduct = "fixed_product"
    }

    public init(siteID: Int64 = 0,
                couponID: Int64,
                code: String,
                amount: String,
                dateCreated: Date,
                dateModified: Date,
                discountType: DiscountType,
                description: String,
                dateExpires: Date?,
                usageCount: Int64,
                individualUse: Bool,
                productIds: [Int64],
                excludedProductIds: [Int64],
                usageLimit: Int64?,
                usageLimitPerUser: Int64?,
                limitUsageToXItems: Int64?,
                freeShipping: Bool,
                productCategories: [Int64],
                excludedProductCategories: [Int64],
                excludeSaleItems: Bool,
                minimumAmount: String,
                maximumAmount: String,
                emailRestrictions: [String],
                usedBy: [String]) {
        self.siteID = siteID
        self.couponID = couponID
        self.code = code
        self.amount = amount
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.mappedDiscountType = discountType
        self.description = description
        self.dateExpires = dateExpires
        self.usageCount = usageCount
        self.individualUse = individualUse
        self.productIds = productIds
        self.excludedProductIds = excludedProductIds
        self.usageLimit = usageLimit
        self.usageLimitPerUser = usageLimitPerUser
        self.limitUsageToXItems = limitUsageToXItems
        self.freeShipping = freeShipping
        self.productCategories = productCategories
        self.excludedProductCategories = excludedProductCategories
        self.excludeSaleItems = excludeSaleItems
        self.minimumAmount = minimumAmount
        self.maximumAmount = maximumAmount
        self.emailRestrictions = emailRestrictions
        self.usedBy = usedBy
    }
}


// MARK: - Codable Conformance

/// Defines all of the Coupon CodingKeys
/// The model is intended to be decoded with`JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase`
/// so any specific `CodingKeys` provided here should be in camel case.
extension Coupon: Codable {
    enum CodingKeys: String, CodingKey {
        case couponID = "id"
        case code
        case amount
        case dateCreated = "dateCreatedGmt"
        case dateModified = "dateModifiedGmt"
        case mappedDiscountType
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
