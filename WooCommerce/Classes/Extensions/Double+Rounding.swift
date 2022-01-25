import Foundation

extension Double {
    /// Returns a rounded value that has the next higher multitude of the same power of 10.
    /// Examples: 62 --> 70, 134 --> 200, 1450 --> 2000, -579 --> -600
    /// - Parameter shouldRoundUp: Whether to round up or down.
    /// - Returns: <#description#>
    func roundedToTheNextSamePowerOfTen(shouldRoundUp: Bool) -> Double {
        guard self != 0 else {
            return 0
        }
        let isNegativeValue = self < 0
        let roundsUp = isNegativeValue ? !shouldRoundUp: shouldRoundUp
        let absoluteValue = abs(self)
        let numberOfDigits = max(floor(log10(absoluteValue)), 0)
        let tenthPowerValue = pow(10, numberOfDigits)
        let numberOfTenthPowerValues = roundsUp ? ceil(absoluteValue / tenthPowerValue): floor(absoluteValue / tenthPowerValue)
        let nextTenthPowerValue = numberOfTenthPowerValues * tenthPowerValue
        return (isNegativeValue ? -1: 1) * nextTenthPowerValue
    }
}
