import Foundation
import Yosemite

public struct MoneyFormatSettings {
    public enum CurrencyPosition: String {
        case left = "left"
        case right = "right"
        case leftSpace = "left_space"
        case rightSpace = "right_space"
    }

    public let currencyPosition: CurrencyPosition
    public let thousandsSeparator: String
    public let decimalSeparator: String
    public let numberOfDecimals: Int

    init(currencyPosition: CurrencyPosition, thousandsSeparator: String, decimalSeparator: String, numberOfDecimals: Int) {
        self.currencyPosition = currencyPosition
        self.thousandsSeparator = thousandsSeparator
        self.decimalSeparator = decimalSeparator
        self.numberOfDecimals = numberOfDecimals
    }

    init() {
        self.init(currencyPosition: .left, thousandsSeparator: ",", decimalSeparator: ".", numberOfDecimals: 2)
    }

    init(siteSettings: [SiteSetting]) {
        guard let wooCurrencyPosition = siteSettings.first(where: { $0.settingID == "woocommerce_currency_pos" })?.value,
            let thousandsSeparator = siteSettings.first(where: { $0.settingID == "woocommerce_price_thousand_sep" })?.value,
            let decimalSeparator = siteSettings.first(where: { $0.settingID == "woocommerce_price_decimal_sep" })?.value,
            let wooNumberOfDecimals = siteSettings.first(where: { $0.settingID == "woocommerce_price_num_decimals" })?.value,
            let numberOfDecimals = Int(wooNumberOfDecimals) else {
                self.init()
                return
        }

        let currencyPosition = MoneyFormatSettings.CurrencyPosition(rawValue: wooCurrencyPosition) ?? .left

        self.init(currencyPosition: currencyPosition, thousandsSeparator: thousandsSeparator, decimalSeparator: decimalSeparator, numberOfDecimals: numberOfDecimals)
    }
}

public class MoneyFormatter {

    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency

        return formatter
    }()


    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: String, currencyCode: String, locale: Locale = .current) -> String? {
        guard let decimal = Decimal(string: value) else {
            return nil
        }

        return format(value: decimal, currencyCode: currencyCode, locale: locale)
    }

    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: Decimal, currencyCode: String, locale: Locale = .current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode
        let decimalNumber = NSDecimalNumber(decimal: value)

        return currencyFormatter.string(from: decimalNumber)
    }

    /// Returns a localized and formatted currency string, or nil if empty or zero.
    ///
    func formatIfNonZero(value: String, currencyCode: String, locale: Locale = .current) -> String? {
        guard value.isEmpty == false else {
            return nil
        }

        guard let decimal = Decimal(string: value) else {
            return nil
        }

        return formatIfNonZero(value: decimal,
                               currencyCode: currencyCode,
                               locale: locale)
    }

    /// Returns a localized and formatted currency string, or nil if value is zero.
    ///
    func formatIfNonZero(value: Decimal, currencyCode: String, locale: Locale = .current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode

        if value.isZero {
            return nil
        }

        let decimalNumber = NSDecimalNumber(decimal: value)

        return currencyFormatter.string(from: decimalNumber)
    }

    /// Returns the symbol only, no formatting applied.
    ///
    func currencySymbol(currencyCode: String, locale: Locale = .current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode

        return currencyFormatter.currencySymbol
    }
}


// MARK: - Manual currency formatting
//
extension MoneyFormatter {
    /// Returns a decimal value from a given string.
    /// - Parameters:
    ///   - stringValue: the string received from the API
    ///
    func convertToDecimal(from stringValue: String) -> NSDecimalNumber? {
        let decimalValue = NSDecimalNumber(string: stringValue)

        guard decimalValue != NSDecimalNumber.notANumber else {
            DDLogError("Error: string input is not a number: \(stringValue)")
            return nil
        }

        return decimalValue
    }

    /// Return a string formatted with the specified decimal separator
    ///
    func localizeDecimal(_ decimal: NSDecimalNumber, with separator: String) -> String {
        let stringValue = decimal.stringValue
        let formattedString = stringValue.replacingOccurrences(of: ".", with: separator)

        return formattedString
    }

    /// Return a string formatted with the specified thousand separator
    ///
    func localizeThousand(_ decimal: NSDecimalNumber, with separator: String) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSeparator = separator
        numberFormatter.groupingSize = 3
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .decimal

        let stringResult = numberFormatter.string(from: decimal)

        return stringResult
    }
}
