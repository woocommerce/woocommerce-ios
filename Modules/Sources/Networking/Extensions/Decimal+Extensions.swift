import Foundation

extension Decimal {

    /// Returns true if the decimal is an integer.
    ///
    public var isInteger: Bool {
        // Based on floating-point arithmetic, we can check the exponent to find out whether the decimal is an integer.
        // Integer example: 12300 has the significand 123 and exponent 2: 123 * 10^2
        // Non-integer example: 12.345 has the significand 12345 and exponent -3: 12345 * 10^-3
        self.exponent >= 0
    }
}
