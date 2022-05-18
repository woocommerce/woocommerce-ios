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
    public let discountType: DiscountType

    public let description: String

    /// Date the coupon will expire.
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
        case percent
        case fixedCart = "fixed_cart"
        case fixedProduct = "fixed_product"
        case other
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
        self.discountType = discountType
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

    /// We need a custom decoding because we are going to not store the `date_expires` property, but only its GMT version `date_expires_gmt`.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        couponID = try container.decode(Int64.self, forKey: .couponID)
        code = try container.decode(String.self, forKey: .code)
        amount = try container.decode(String.self, forKey: .amount)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        dateModified = try container.decode(Date.self, forKey: .dateModified)
        discountType = try container.decode(DiscountType.self, forKey: .discountType)
        description = try container.decode(String.self, forKey: .description)
        dateExpires = try container.decodeIfPresent(Date.self, forKey: .dateExpires)
        usageCount = try container.decode(Int64.self, forKey: .usageCount)
        individualUse = try container.decode(Bool.self, forKey: .individualUse)
        productIds = try container.decode([Int64].self, forKey: .productIds)
        excludedProductIds = try container.decode([Int64].self, forKey: .excludedProductIds)
        usageLimit = try container.decodeIfPresent(Int64.self, forKey: .usageLimit)
        usageLimitPerUser = try container.decodeIfPresent(Int64.self, forKey: .usageLimitPerUser)
        limitUsageToXItems = try container.decodeIfPresent(Int64.self, forKey: .limitUsageToXItems)
        freeShipping = try container.decode(Bool.self, forKey: .freeShipping)
        productCategories = try container.decode([Int64].self, forKey: .productCategories)
        excludedProductCategories = try container.decode([Int64].self, forKey: .excludedProductCategories)
        excludeSaleItems = try container.decode(Bool.self, forKey: .excludeSaleItems)
        minimumAmount = try container.decode(String.self, forKey: .minimumAmount)
        maximumAmount = try container.decode(String.self, forKey: .maximumAmount)
        emailRestrictions = try container.decode([String].self, forKey: .emailRestrictions)
        usedBy = try container.decode([String].self, forKey: .usedBy)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(code, forKey: .code)
        try container.encode(amount, forKey: .amount)
        try container.encode(discountType, forKey: .discountType)
        try container.encode(description, forKey: .description)
        try container.encode(productIds, forKey: .productIds)
        try container.encode(excludedProductIds, forKey: .excludedProductIds)
        try container.encode(usageLimit, forKey: .usageLimit)
        try container.encode(usageLimitPerUser, forKey: .usageLimitPerUser)
        try container.encode(limitUsageToXItems, forKey: .limitUsageToXItems)
        try container.encode(freeShipping, forKey: .freeShipping)
        try container.encode(productCategories, forKey: .productCategories)
        try container.encode(excludedProductCategories, forKey: .excludedProductCategories)
        try container.encode(minimumAmount, forKey: .minimumAmount)
        try container.encode(maximumAmount, forKey: .maximumAmount)
        try container.encode(emailRestrictions, forKey: .emailRestrictions)

        /// Encoding `dateExpires` has some special conditions.
        /// - Encode the content to update the value.
        /// - Encode an empty string to clear the value (nil is not allowed, and the value will be not updated).
        ///
        switch dateExpires {
        case .some(let content):
            try container.encode(content, forKey: .dateExpires)
        case .none:
            try container.encode("", forKey: .dateExpires)
        }
    }

    /// JSON decoder appropriate for `Coupon` responses.
    ///
    static let decoder: JSONDecoder = {
        let couponDecoder = JSONDecoder()
        couponDecoder.keyDecodingStrategy = .convertFromSnakeCase
        couponDecoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        return couponDecoder
    }()

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
        case discountType
        case description
        case dateExpires = "dateExpires"
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

extension Coupon.DiscountType: Codable {
    public init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = Coupon.DiscountType(rawValue: rawValue) ?? .other
    }
}


// MARK: - Other Conformances

extension Coupon: GeneratedCopiable, GeneratedFakeable, Equatable {}

extension Coupon.DiscountType: GeneratedCopiable, GeneratedFakeable, Equatable {}
