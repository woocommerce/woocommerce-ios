import Foundation

/// Represents a coupon applied to the WooCommerce Store API Cart.
///
public struct StoreAPICartCoupon: Decodable, Equatable {
    /// Coupon code.
    public let code: String

    /// Discount type (e.g., "percent", "fixed_cart", "fixed_product").
    public let discountType: String

    /// Totals for this coupon.
    public let totals: StoreAPICartCouponTotals

    public init(
        code: String,
        discountType: String,
        totals: StoreAPICartCouponTotals
    ) {
        self.code = code
        self.discountType = discountType
        self.totals = totals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        code = try container.decode(String.self, forKey: .code)
        discountType = try container.decodeIfPresent(String.self, forKey: .discountType) ?? ""
        totals = try container.decode(StoreAPICartCouponTotals.self, forKey: .totals)
    }
}

private extension StoreAPICartCoupon {
    enum CodingKeys: String, CodingKey {
        case code
        case discountType = "discount_type"
        case totals
    }
}

// MARK: - Coupon Totals

/// Totals for a coupon in the cart.
///
public struct StoreAPICartCouponTotals: Decodable, Equatable {
    /// Total discount from this coupon in minor units.
    public let totalDiscount: String

    /// Total discount tax in minor units.
    public let totalDiscountTax: String

    /// Currency code.
    public let currencyCode: String

    /// Number of decimals.
    public let currencyMinorUnit: Int

    public init(
        totalDiscount: String,
        totalDiscountTax: String,
        currencyCode: String,
        currencyMinorUnit: Int
    ) {
        self.totalDiscount = totalDiscount
        self.totalDiscountTax = totalDiscountTax
        self.currencyCode = currencyCode
        self.currencyMinorUnit = currencyMinorUnit
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        totalDiscount = try container.decode(String.self, forKey: .totalDiscount)
        totalDiscountTax = try container.decodeIfPresent(String.self, forKey: .totalDiscountTax) ?? "0"
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        currencyMinorUnit = try container.decodeIfPresent(Int.self, forKey: .currencyMinorUnit) ?? 2
    }

    private enum CodingKeys: String, CodingKey {
        case totalDiscount = "total_discount"
        case totalDiscountTax = "total_discount_tax"
        case currencyCode = "currency_code"
        case currencyMinorUnit = "currency_minor_unit"
    }
}
