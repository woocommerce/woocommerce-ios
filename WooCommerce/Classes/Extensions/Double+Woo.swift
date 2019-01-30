import Foundation


extension Double {

    /// Provides a short, friendly, and *localized* representation of the receiver.
    ///
    /// Discussion: If the receiver value is between -1000 & 1000, the value is rounded to the nearest Int with
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
    func humanReadableString() -> String {
        let num = Double(self)

        guard (-999.99999999..<1000.0 ~= num) == false else {
            // If the starting value is between -1000 and 1000, return the rounded Int version
            let numFormatter = NumberFormatter()
            numFormatter.allowsFloats = true
            numFormatter.minimumIntegerDigits = 1
            numFormatter.maximumFractionDigits = 0
            numFormatter.roundingMode = .down
            let returnString = numFormatter.string(from: NSNumber(value: num)) ?? Constants.zeroString

            // We need to check for a -0 value here before returning the string
            return returnString == Constants.negativeZeroString ? Constants.zeroString : returnString
        }

        return abbreviatedString(for: num)
    }
}


// MARK: - Private helpers
//
private extension Double {

    func abbreviatedString(for number: Double) -> String {
        let absNumber = fabs(number)
        let abbreviation: Abbrevation = {
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
        let numFormatter = NumberFormatter()
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 1
        numFormatter.maximumFractionDigits = 1

        let finalValue = NSNumber(value: value)
        return numFormatter.string(from: finalValue) ?? Constants.zeroString
    }
}


// MARK: - Constants!
//
private extension Double {

    typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)

    enum Constants {
        static let negativeZeroString = "-0"
        static let zeroString         = "0"

        static let abbreviations: [Abbrevation] = [(0, 1, ""),
                                                   (999.0, 1_000.0, "k"),
                                                   (999_999.0, 1_000_000.0, "m"),
                                                   (999_999_999.0, 1_000_000_000.0, "b"),
                                                   (999_999_999_999.0, 1_000_000_000_000.0, "t")]
    }
}
