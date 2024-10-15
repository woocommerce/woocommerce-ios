import WooFoundation

/// Sanitize separators that has spaces within it. Example ", " or ". "
/// Separators with spaces are not supported by native iOS decimal formatters
/// which causes the issue formatting and converting numbers to and from the decimals
///
extension CurrencySettings {
    var sanitizedDecimalSeparator: String {
        return decimalSeparator.replacingOccurrences(of: " ", with: "")
    }

    var sanitizedGroupingSeparator: String {
        return groupingSeparator.replacingOccurrences(of: " ", with: "")
    }
}
