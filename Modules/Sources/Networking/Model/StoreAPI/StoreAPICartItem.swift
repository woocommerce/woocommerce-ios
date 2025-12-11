import Foundation

/// Represents an item in the WooCommerce Store API Cart.
///
public struct StoreAPICartItem: Decodable, Equatable {
    /// Unique identifier for the item within the cart (used for update/remove operations).
    public let key: String

    /// Product ID.
    public let id: Int64

    /// Variation ID (0 if not a variation).
    public let variationID: Int64

    /// Quantity of this item in the cart.
    public let quantity: Int

    /// Product name.
    public let name: String

    /// Short description of the product.
    public let shortDescription: String

    /// Product SKU.
    public let sku: String

    /// Product prices information.
    public let prices: StoreAPICartItemPrices

    /// Item totals.
    public let totals: StoreAPICartItemTotals

    public init(
        key: String,
        id: Int64,
        variationID: Int64,
        quantity: Int,
        name: String,
        shortDescription: String,
        sku: String,
        prices: StoreAPICartItemPrices,
        totals: StoreAPICartItemTotals
    ) {
        self.key = key
        self.id = id
        self.variationID = variationID
        self.quantity = quantity
        self.name = name
        self.shortDescription = shortDescription
        self.sku = sku
        self.prices = prices
        self.totals = totals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        key = try container.decode(String.self, forKey: .key)
        id = try container.decode(Int64.self, forKey: .id)
        variationID = try container.decodeIfPresent(Int64.self, forKey: .variationID) ?? 0
        quantity = try container.decode(Int.self, forKey: .quantity)
        name = try container.decode(String.self, forKey: .name)
        shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription) ?? ""
        sku = try container.decodeIfPresent(String.self, forKey: .sku) ?? ""
        prices = try container.decode(StoreAPICartItemPrices.self, forKey: .prices)
        totals = try container.decode(StoreAPICartItemTotals.self, forKey: .totals)
    }
}

private extension StoreAPICartItem {
    enum CodingKeys: String, CodingKey {
        case key
        case id
        case variationID = "variation_id"
        case quantity
        case name
        case shortDescription = "short_description"
        case sku
        case prices
        case totals
    }
}

// MARK: - Item Prices

/// Prices information for a cart item.
///
public struct StoreAPICartItemPrices: Decodable, Equatable {
    /// Currency code (e.g., "USD").
    public let currencyCode: String

    /// Number of decimal places for the currency.
    public let currencyDecimalSeparator: String

    /// Thousand separator for the currency.
    public let currencyThousandSeparator: String

    /// Number of decimals.
    public let currencyMinorUnit: Int

    /// Currency prefix.
    public let currencyPrefix: String

    /// Currency suffix.
    public let currencySuffix: String

    /// Price of a single item (in minor units).
    public let price: String

    /// Regular price of a single item (in minor units).
    public let regularPrice: String

    /// Sale price of a single item (in minor units), empty if not on sale.
    public let salePrice: String

    public init(
        currencyCode: String,
        currencyDecimalSeparator: String,
        currencyThousandSeparator: String,
        currencyMinorUnit: Int,
        currencyPrefix: String,
        currencySuffix: String,
        price: String,
        regularPrice: String,
        salePrice: String
    ) {
        self.currencyCode = currencyCode
        self.currencyDecimalSeparator = currencyDecimalSeparator
        self.currencyThousandSeparator = currencyThousandSeparator
        self.currencyMinorUnit = currencyMinorUnit
        self.currencyPrefix = currencyPrefix
        self.currencySuffix = currencySuffix
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        currencyDecimalSeparator = try container.decodeIfPresent(String.self, forKey: .currencyDecimalSeparator) ?? "."
        currencyThousandSeparator = try container.decodeIfPresent(String.self, forKey: .currencyThousandSeparator) ?? ","
        currencyMinorUnit = try container.decodeIfPresent(Int.self, forKey: .currencyMinorUnit) ?? 2
        currencyPrefix = try container.decodeIfPresent(String.self, forKey: .currencyPrefix) ?? ""
        currencySuffix = try container.decodeIfPresent(String.self, forKey: .currencySuffix) ?? ""
        price = try container.decode(String.self, forKey: .price)
        regularPrice = try container.decode(String.self, forKey: .regularPrice)
        salePrice = try container.decodeIfPresent(String.self, forKey: .salePrice) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case currencyCode = "currency_code"
        case currencyDecimalSeparator = "currency_decimal_separator"
        case currencyThousandSeparator = "currency_thousand_separator"
        case currencyMinorUnit = "currency_minor_unit"
        case currencyPrefix = "currency_prefix"
        case currencySuffix = "currency_suffix"
        case price
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
    }
}

// MARK: - Item Totals

/// Totals for a cart item.
///
public struct StoreAPICartItemTotals: Decodable, Equatable {
    /// Line subtotal (before discounts) in minor units.
    public let lineSubtotal: String

    /// Line subtotal tax in minor units.
    public let lineSubtotalTax: String

    /// Line total (after discounts) in minor units.
    public let lineTotal: String

    /// Line total tax in minor units.
    public let lineTotalTax: String

    /// Currency code.
    public let currencyCode: String

    /// Number of decimals.
    public let currencyMinorUnit: Int

    public init(
        lineSubtotal: String,
        lineSubtotalTax: String,
        lineTotal: String,
        lineTotalTax: String,
        currencyCode: String,
        currencyMinorUnit: Int
    ) {
        self.lineSubtotal = lineSubtotal
        self.lineSubtotalTax = lineSubtotalTax
        self.lineTotal = lineTotal
        self.lineTotalTax = lineTotalTax
        self.currencyCode = currencyCode
        self.currencyMinorUnit = currencyMinorUnit
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        lineSubtotal = try container.decode(String.self, forKey: .lineSubtotal)
        lineSubtotalTax = try container.decodeIfPresent(String.self, forKey: .lineSubtotalTax) ?? "0"
        lineTotal = try container.decode(String.self, forKey: .lineTotal)
        lineTotalTax = try container.decodeIfPresent(String.self, forKey: .lineTotalTax) ?? "0"
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        currencyMinorUnit = try container.decodeIfPresent(Int.self, forKey: .currencyMinorUnit) ?? 2
    }

    private enum CodingKeys: String, CodingKey {
        case lineSubtotal = "line_subtotal"
        case lineSubtotalTax = "line_subtotal_tax"
        case lineTotal = "line_total"
        case lineTotalTax = "line_total_tax"
        case currencyCode = "currency_code"
        case currencyMinorUnit = "currency_minor_unit"
    }
}
