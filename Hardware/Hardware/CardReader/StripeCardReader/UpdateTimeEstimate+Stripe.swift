import StripeTerminal

extension Hardware.UpdateTimeEstimate {
    init(_ estimate: StripeTerminal.UpdateTimeEstimate) {
        switch estimate {
        case .estimateLessThan1Minute:
            self = .lessThanOneMinute
        case .estimate1To2Minutes:
            self = .betweenOneAndTwoMinutes
        case .estimate2To5Minutes:
            self = .betweenTwoAndFiveMinutes
        case .estimate5To15Minutes:
            self = .betweenFiveAndFifteenMinutes
        default:
            self = .indeterminate
        }
    }
}
