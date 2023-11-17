import enum Yosemite.SubscriptionPeriod

extension SubscriptionPeriod {
    /// Returns the max allowed free trial limit for the period
    ///
    var freeTrialLimit: Int {
        switch self {
        case .day:
            return 90
        case .week:
            return 52
        case .month:
            return 24
        case .year:
            return 5
        }
    }
}
