import Foundation

extension NSDecimalNumber {

    /// Returns true if the receiver is equal to zero, false otherwise.
    ///
    func isZero() -> Bool {
        if NSDecimalNumber.zero.compare(self) == .orderedSame {
            return true
        }

        return false
    }

    /// Returns true if the decimalValue is negative, false otherwise.
    ///
    func isNegative() -> Bool {
        return self.decimalValue._isNegative == 1
    }

    /// Provides a short, friendly, and *localized* representation of the receiver.
    ///
    /// - Parameter roundSmallNumbers: if `true`, small numbers are rounded, if `false`, no rounding occurs (defaults to true)
    /// - Returns: a human readable string value
    ///
    ///  - If `roundSmallNumbers` is set to `true` *and* the receiver value is between -1000 & 1000,
    ///    the value is rounded to the nearest Int with a "toward zero" rounding strategy.
    ///  - Regardless of how `roundSmallNumbers` is set, when the receiver value is above 1000 or below -1000,
    ///    the value is rounded to the nearest tenth and the appropriate abbreviation will be appended (k, m, b, t).
    ///
    /// Examples (with rounding):
    ///  - 0 becomes "0"
    ///  - 198.44 becomes "198"
    ///  - 198.88 becomes "198"
    ///  - 999 becomes "999"
    ///  - 1000 becomes "1.0k"
    ///  - 999999 becomes "1.0m"
    ///  - 1000000 becomes "1.0m"
    ///  - 1000000000 becomes "1.0b"
    ///  - 1000000000000 becomes "1.0t"
    ///  - 5800199.56 becomes "5.8m"
    ///
    /// Examples (*no* rounding):
    ///  - 0 becomes "0"
    ///  - 198.44 becomes "198.44"
    ///  - 198.88 becomes "198.58"
    ///  - 999 becomes "999"
    ///  - 1000 becomes "1.0k"
    ///  - 999999 becomes "1.0m"
    ///  - 1000000 becomes "1.0m"
    ///  - 1000000000 becomes "1.0b"
    ///  - 1000000000000 becomes "1.0t"
    ///  - 5800199.56 becomes "5.8m"
    ///
    /// Note: This helper function does work with negative values as well.
    ///
    func humanReadableString(roundSmallNumbers: Bool = true) -> String {
        guard roundSmallNumbers == false else {
            return self.doubleValue.humanReadableString()
        }

        // If the receiver value is in-between the lower and upper limits return the value passed in, otherwise
        // send back the friendly (large) number
        if self.compare(Constants.upperSmallNumberLimit) == .orderedAscending &&
            self.compare(Constants.lowerSmallNumberLimit) == .orderedDescending {
            return self.stringValue
        } else {
            return self.doubleValue.humanReadableString()
        }
    }
}


// MARK: - Constants!
//
private extension NSDecimalNumber {

    enum Constants {
        static let upperSmallNumberLimit = NSDecimalNumber(string: "1000.0")
        static let lowerSmallNumberLimit = NSDecimalNumber(string: "-1000.0")
    }
}
