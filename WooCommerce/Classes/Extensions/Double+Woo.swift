import Foundation


extension Double {

    /// Provides a friendly, shorted representation of the current Double value. If the value is above 1000,
    /// the appropriate abbreviation will be appended to the rounded number (k, m, b, t).
    /// Examples:
    ///     * 0 becomes 0
    ///     * 198.44 becomes 198
    ///     * 1000 becomes "1.0k"
    ///     * 1000000 becomes "1.0m"
    ///     * 1000000000 becomes "1.0b"
    ///     * 1000000000000 becomes "1.0t"
    ///     * 100101 becomes "100.1k"
    ///
    /// This helper function does work with negative values as well.
    ///
    func friendlyString() -> String {
        var num = Double(self)
        let sign = ((num < 0) ? "-" : "" );
        num = fabs(num);
        if -1000.0..<1000.0 ~= num {
            let intNum = Int(num)
            if intNum == 0 {
                return "\(Int(num))";
            }
            return "\(sign)\(Int(num))";
        }

        let exp = Int(log10(num) / 3.0 ); // log10(1000)
        let units = ["k", "m", "b", "t"];
        let roundedNum: Double = Foundation.round(10 * num / pow(1000.0, Double(exp))) / 10;

        return "\(sign)\(roundedNum)\(units[exp-1])";
    }

}
