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
        var num = Double(self)
        let sign = ((num < 0) ? "-" : "" )
        num = fabs(num)
        if -1000.0..<1000.0 ~= num {
            let intNum = Int(num)
            if intNum == 0 {
                return "\(Int(num))"
            }
            return "\(sign)\(Int(num))"
        }

        let exp = Int(log10(num) / 3.0 ) // log10(1000)
        let units = ["k", "m", "b", "t"]
        let roundedNum: Double = Foundation.round(10 * num / pow(1000.0, Double(exp))) / 10

        if roundedNum == 1000.0 {
            return "\(sign)\(1.0)\(units[exp])"
        } else {
            return "\(sign)\(roundedNum)\(units[exp-1])"
        }
    }

}
