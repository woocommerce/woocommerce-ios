import Foundation

/// Stateless utility for sanitizing and formatting currency input text.
///
/// Handles device-to-store separator conversion, character filtering, and fraction digit enforcement.
///
public struct CurrencyInputSanitizer {
    private let currencySettings: CurrencySettings
    private let deviceDecimalSeparator: String
    public let currencySymbol: String
    private let currencyFormatter: CurrencyFormatter
    private let decimalFormatter: NumberFormatter

    private var storeDecimalSeparator: String { currencySettings.sanitizedDecimalSeparator }
    private var fractionDigits: Int { currencySettings.fractionDigits }

    public init(currencySettings: CurrencySettings,
                deviceDecimalSeparator: String? = nil) {
        self.currencySettings = currencySettings
        self.currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)
        self.deviceDecimalSeparator = deviceDecimalSeparator ?? Locale.autoupdatingCurrent.decimalSeparator ?? "."
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = currencySettings.sanitizedDecimalSeparator
        formatter.minimumFractionDigits = currencySettings.fractionDigits
        formatter.maximumFractionDigits = currencySettings.fractionDigits
        formatter.roundingMode = .halfUp
        self.decimalFormatter = formatter
    }

    /// Validates and sanitizes currency input text.
    ///
    /// - Replaces the device decimal separator with the store decimal separator
    /// - Filters to only digits and the store decimal separator
    /// - Rejects input with multiple decimal separators
    /// - Rejects input exceeding the allowed fraction digits
    /// - Rejects decimal separator when fraction digits is 0
    ///
    /// - Parameter text: Raw user input text
    /// - Returns: Sanitized text if valid, `nil` if invalid
    public func sanitize(_ text: String) -> String? {
        if text.isEmpty {
            return ""
        }

        var sanitized = text
        if deviceDecimalSeparator != storeDecimalSeparator {
            sanitized = sanitized.replacingOccurrences(of: deviceDecimalSeparator, with: storeDecimalSeparator)
        }

        sanitized = String(sanitized.filter { char in
            char.isNumber || String(char) == storeDecimalSeparator
        })

        if fractionDigits == 0 && sanitized.contains(storeDecimalSeparator) {
            return nil
        }

        let separatorCount = sanitized.components(separatedBy: storeDecimalSeparator).count - 1
        if separatorCount > 1 {
            return nil
        }

        if let separatorRange = sanitized.range(of: storeDecimalSeparator) {
            let fractionPart = sanitized[separatorRange.upperBound...]
            if fractionPart.count > fractionDigits {
                return nil
            }
        }

        return sanitized
    }

    /// Formats a Decimal to a raw display string (digits + separator, no grouping, no symbol).
    ///
    /// - Parameter value: The decimal value to format
    /// - Returns: Formatted string using the store decimal separator and fraction digits
    public func formatDecimal(_ value: Decimal) -> String {
        decimalFormatter.string(from: value as NSDecimalNumber) ?? "0"
    }

    /// Adds the currency symbol to an amount string based on the store position settings.
    ///
    /// - Parameters:
    ///   - amount: The raw amount string (no symbol)
    ///   - isNegative: Whether the amount is negative (default: `false`)
    /// - Returns: The amount string with the currency symbol in the correct position
    public func addCurrencySymbol(to amount: String, isNegative: Bool = false) -> String {
        currencyFormatter.formatCurrency(
            using: amount,
            currencyPosition: currencySettings.currencyPosition,
            currencySymbol: currencySymbol,
            isNegative: isNegative
        )
    }
}
