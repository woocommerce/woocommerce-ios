import Foundation


extension Double {

    /// Provides a short, friendly, and *localized* representation of the receiver.
    ///
    /// - Returns: a human readable string value
    ///
    /// **WARNING:** If you are considering formatting currency values, please do **NOT** use this function —
    /// check out `CurrencyFormatter.formatHumanReadableAmount()` instead! If you **still** decide to use this
    /// function, Thuy will hunt you down 🔪.
    ///
    /// If the receiver value is between -1000 & 1000, the value is rounded to the nearest Int with
    /// a "toward zero" rounding strategy. If the value is above 1000 or below -1000, the value is rounded
    /// to the nearest tenth and the appropriate abbreviation will be appended (k, m, b, t).
    ///
    /// Examples:
    ///  - 0 becomes "0"
    ///  - 198.44 becomes "198"
    ///  - 198.88 becomes "198"
    ///  - 999 becomes "999"
    ///  - 1000 becomes "1.0k"
    ///  - 999999 becomes "1.0m"
    ///  - 1000000 becomes "1.0m"
    ///  - 1000000000 becomes "1.0b"
    ///  - 1000000000000 becomes "1.0t"
    ///  - 5800199 becomes "5.8m"
    ///
    /// Note: This helper function does work with negative values as well.
    ///
    /// - Parameter shouldHideDecimalsForIntegerAbbreviatedValue: Whether decimal digits should be hidden when the abbreviated value is an integer.
    ///                                                           If `false`, a decimal digit is always shown.
    func humanReadableString(shouldHideDecimalsForIntegerAbbreviatedValue: Bool = false) -> String {
        let num = Double(self)

        // If the starting value is between -1000 and 1000, return the rounded Int version
        guard (-999.99999999..<1000.0 ~= num) == false else {

            let returnString = Formatters.smallNumberFormatter.string(from: NSNumber(value: num)) ?? Constants.zeroString

            // We need to check for a -0 value here before returning the string
            return returnString == Constants.negativeZeroString ? Constants.zeroString : returnString
        }

        return abbreviatedString(for: num, shouldHideDecimalsForIntegerAbbreviatedValue: shouldHideDecimalsForIntegerAbbreviatedValue)
    }
}


// MARK: - Private helpers
//
private extension Double {

    func abbreviatedString(for number: Double, shouldHideDecimalsForIntegerAbbreviatedValue: Bool) -> String {
        let absNumber = fabs(number)
        let abbreviation: Abbreviation = {
            var prevAbbreviation = Constants.abbreviations[0]
            for tmpAbbreviation in Constants.abbreviations {
                if absNumber < tmpAbbreviation.threshold {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        } ()

        let value = number / abbreviation.divisor
        let numFormatter = Formatters.largeNumberFormatter
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix

        if shouldHideDecimalsForIntegerAbbreviatedValue {
            numFormatter.minimumFractionDigits = 0
        }

        let finalValue = NSNumber(value: value)
        return numFormatter.string(from: finalValue) ?? Constants.zeroString
    }
}


// MARK: - Constants!
//
private extension Double {

    typealias Abbreviation = (threshold: Double, divisor: Double, suffix: String)

    enum Constants {
        static let negativeZeroString = "-0"
        static let zeroString         = "0"

        static let abbreviations: [Abbreviation] = [(0, 1, ""),
                                                   (999.0, 1_000.0, "k"),
                                                   (999_999.0, 1_000_000.0, "m"),
                                                   (999_999_999.0, 1_000_000_000.0, "b"),
                                                   (999_999_999_999.0, 1_000_000_000_000.0, "t")]
    }

    enum Formatters {

        /// Formatter used for numbers between -1000 and 1000 (exclusive)
        ///
        static let smallNumberFormatter: NumberFormatter = {
            let numFormatter = NumberFormatter()
            numFormatter.allowsFloats = true
            numFormatter.minimumIntegerDigits = 1
            numFormatter.maximumFractionDigits = 0
            numFormatter.roundingMode = .down
            return numFormatter
        }()

        /// Formatter used for numbers greater than -1000 and greater that 1000 (inclusive)
        ///
        static var largeNumberFormatter: NumberFormatter {
            let numFormatter = NumberFormatter()
            numFormatter.allowsFloats = true
            numFormatter.minimumIntegerDigits = 1
            numFormatter.minimumFractionDigits = 1
            numFormatter.maximumFractionDigits = 1
            return numFormatter
        }
    }
}
