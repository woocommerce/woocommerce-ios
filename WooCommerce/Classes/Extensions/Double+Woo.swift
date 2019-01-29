import Foundation


extension Double {

    /// Provides a short, friendly representation of the current Double value. If the value is
    /// below 1000, the decimal is stripped and the string returned will look like an Int. If the value
    /// is above 1000, the value is rounded to the nearest tenth and the appropriate abbreviation
    /// will be appended (k, m, b, t).
    ///
    /// Examples:
    ///  - 0 becomes "0"
    ///  - 198.44 becomes "198"
    ///  - 999 becomes "999"
    ///  - 1000 becomes "1.0k"
    ///  - 999999 becomes "1.0m"
    ///  - 1000000 becomes "1.0m"
    ///  - 1000000000 becomes "1.0b"
    ///  - 1000000000000 becomes "1.0t"
    ///  - 5800199 becomes "5.8m"
    ///
    /// This helper function does work with negative values as well.
    ///
    func humanReadableString() -> String {
        let num = Double(self)

        guard (-999.99999999..<1000.0 ~= num) == false else {
            // If the starting value is between -1000 and 1000, just return the rounded Int version
            return "\(Int(num.rounded(.towardZero)))"
        }

        return abbreviatedString(for: num)
    }

}


// MARK: - Private helpers
//
private extension Double {

    func abbreviatedString(for number: Double) -> String {
        typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)
        let abbreviations: [Abbrevation] = [(0, 1, ""),
                                           (1_000.0, 1_000.0, "k"),
                                           (1_000_000.0, 1_000_000.0, "m"),
                                           (1_000_000_000.0, 1_000_000_000.0, "b"),
                                           (1_000_000_000_000.0, 1_000_000_000_000.0, "t")]

        let absNumber = fabs(number)
        let abbreviation: Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if (absNumber < tmpAbbreviation.threshold) {
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

        let finalValue = NSNumber(value:value)
        return numFormatter.string(from: finalValue) ?? "0"
    }
}
