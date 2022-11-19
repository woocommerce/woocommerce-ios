import Foundation

public class AnalyticsHubTimeRange {
    
    enum SelectionType {
        case today
        case weekToDate
        case monthToDate
        case yearToDate
    }
}

extension Date {
    func startOfCurrentMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func startOfLastMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: self)!
    }
}
