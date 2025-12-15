import Foundation

/// Represents the totals for a WooCommerce Store API Cart.
///
public struct StoreAPICartTotals: Decodable, Equatable {
    /// Currency code (e.g., "USD").
    public let currencyCode: String

    /// Currency symbol (e.g., "$").
    public let currencySymbol: String

    /// Number of decimals.
    public let currencyMinorUnit: Int

    /// Decimal separator.
    public let currencyDecimalSeparator: String

    /// Thousand separator.
    public let currencyThousandSeparator: String

    /// Currency prefix.
    public let currencyPrefix: String

    /// Currency suffix.
    public let currencySuffix: String

    /// Total price of items in the cart (in minor units).
    public let totalItems: String

    /// Total tax on items in the cart (in minor units).
    public let totalItemsTax: String

    /// Total fees in the cart (in minor units).
    public let totalFees: String

    /// Total fees tax (in minor units).
    public let totalFeesTax: String

    /// Total discount from coupons (in minor units).
    public let totalDiscount: String

    /// Total discount tax (in minor units).
    public let totalDiscountTax: String

    /// Total shipping cost (in minor units).
    public let totalShipping: String

    /// Total shipping tax (in minor units).
    public let totalShippingTax: String

    /// Total tax (in minor units).
    public let totalTax: String

    /// Total price of the cart (in minor units).
    public let totalPrice: String

    public init(
        currencyCode: String,
        currencySymbol: String,
        currencyMinorUnit: Int,
        currencyDecimalSeparator: String,
        currencyThousandSeparator: String,
        currencyPrefix: String,
        currencySuffix: String,
        totalItems: String,
        totalItemsTax: String,
        totalFees: String,
        totalFeesTax: String,
        totalDiscount: String,
        totalDiscountTax: String,
        totalShipping: String,
        totalShippingTax: String,
        totalTax: String,
        totalPrice: String
    ) {
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.currencyMinorUnit = currencyMinorUnit
        self.currencyDecimalSeparator = currencyDecimalSeparator
        self.currencyThousandSeparator = currencyThousandSeparator
        self.currencyPrefix = currencyPrefix
        self.currencySuffix = currencySuffix
        self.totalItems = totalItems
        self.totalItemsTax = totalItemsTax
        self.totalFees = totalFees
        self.totalFeesTax = totalFeesTax
        self.totalDiscount = totalDiscount
        self.totalDiscountTax = totalDiscountTax
        self.totalShipping = totalShipping
        self.totalShippingTax = totalShippingTax
        self.totalTax = totalTax
        self.totalPrice = totalPrice
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol) ?? ""
        currencyMinorUnit = try container.decodeIfPresent(Int.self, forKey: .currencyMinorUnit) ?? 2
        currencyDecimalSeparator = try container.decodeIfPresent(String.self, forKey: .currencyDecimalSeparator) ?? "."
        currencyThousandSeparator = try container.decodeIfPresent(String.self, forKey: .currencyThousandSeparator) ?? ","
        currencyPrefix = try container.decodeIfPresent(String.self, forKey: .currencyPrefix) ?? ""
        currencySuffix = try container.decodeIfPresent(String.self, forKey: .currencySuffix) ?? ""
        totalItems = try container.decode(String.self, forKey: .totalItems)
        totalItemsTax = try container.decodeIfPresent(String.self, forKey: .totalItemsTax) ?? "0"
        totalFees = try container.decodeIfPresent(String.self, forKey: .totalFees) ?? "0"
        totalFeesTax = try container.decodeIfPresent(String.self, forKey: .totalFeesTax) ?? "0"
        totalDiscount = try container.decodeIfPresent(String.self, forKey: .totalDiscount) ?? "0"
        totalDiscountTax = try container.decodeIfPresent(String.self, forKey: .totalDiscountTax) ?? "0"
        totalShipping = try container.decodeIfPresent(String.self, forKey: .totalShipping) ?? "0"
        totalShippingTax = try container.decodeIfPresent(String.self, forKey: .totalShippingTax) ?? "0"
        totalTax = try container.decodeIfPresent(String.self, forKey: .totalTax) ?? "0"
        totalPrice = try container.decode(String.self, forKey: .totalPrice)
    }
}

// MARK: - Formatting Helpers
//
public extension StoreAPICartTotals {
    /// Converts a value from minor units (cents) to a decimal string.
    ///
    /// Store API returns values in minor units (e.g., "1000" for $10.00).
    /// This converts them to decimal format (e.g., "10.00") for compatibility
    /// with REST API models like `Order` which expect decimal strings.
    ///
    /// - Parameter minorUnitsValue: The value in minor units as a string.
    /// - Returns: The value as a decimal string.
    ///
    func formatAsDecimalString(_ minorUnitsValue: String) -> String {
        guard let intValue = Int(minorUnitsValue) else {
            return minorUnitsValue
        }

        let divisor = pow(10.0, Double(currencyMinorUnit))
        let decimalValue = Double(intValue) / divisor

        return String(format: "%.\(currencyMinorUnit)f", decimalValue)
    }

    /// Converts a value from minor units to a formatted currency string for display.
    ///
    /// Store API returns values in minor units (e.g., "1000" for $10.00).
    /// This formats them with the currency symbol and separators (e.g., "$10.00").
    ///
    /// - Parameter minorUnitsValue: The value in minor units as a string.
    /// - Returns: The formatted currency string for display.
    ///
    func formatAsCurrencyString(_ minorUnitsValue: String) -> String {
        guard let intValue = Int(minorUnitsValue) else {
            return minorUnitsValue
        }

        let divisor = pow(10.0, Double(currencyMinorUnit))
        let decimalValue = Double(intValue) / divisor

        // Format the number with proper decimal places
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = currencyMinorUnit
        formatter.maximumFractionDigits = currencyMinorUnit
        formatter.decimalSeparator = currencyDecimalSeparator
        formatter.groupingSeparator = currencyThousandSeparator
        formatter.usesGroupingSeparator = true

        let formattedNumber = formatter.string(from: NSNumber(value: decimalValue)) ?? String(format: "%.\(currencyMinorUnit)f", decimalValue)

        return "\(currencyPrefix)\(formattedNumber)\(currencySuffix)"
    }

    /// Returns the total price as a Decimal value.
    ///
    var totalPriceDecimal: Decimal {
        guard let intValue = Int(totalPrice) else {
            return 0
        }
        return Decimal(intValue) / pow(10, currencyMinorUnit)
    }
}

private extension StoreAPICartTotals {
    enum CodingKeys: String, CodingKey {
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyMinorUnit = "currency_minor_unit"
        case currencyDecimalSeparator = "currency_decimal_separator"
        case currencyThousandSeparator = "currency_thousand_separator"
        case currencyPrefix = "currency_prefix"
        case currencySuffix = "currency_suffix"
        case totalItems = "total_items"
        case totalItemsTax = "total_items_tax"
        case totalFees = "total_fees"
        case totalFeesTax = "total_fees_tax"
        case totalDiscount = "total_discount"
        case totalDiscountTax = "total_discount_tax"
        case totalShipping = "total_shipping"
        case totalShippingTax = "total_shipping_tax"
        case totalTax = "total_tax"
        case totalPrice = "total_price"
    }
}
