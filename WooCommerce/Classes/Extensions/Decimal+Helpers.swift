import Foundation

extension Decimal {

    /// Returns the int value of a decimal. We ensure we round up our Decimal before converting it to an Int, using NSDecimalRound.
    ///
    var intValue: Int {
        NSDecimalNumber(decimal: whole).intValue
    }

    private func rounded(_ roundingMode: NSDecimalNumber.RoundingMode = .up, scale: Int = 0) -> Self {
        var result = Self()
        var number = self
        NSDecimalRound(&result, &number, scale, roundingMode)
        return result
    }

    private var whole: Self { rounded( self < 0 ? .down : .up) }

    private var fraction: Self { self - whole }

}
