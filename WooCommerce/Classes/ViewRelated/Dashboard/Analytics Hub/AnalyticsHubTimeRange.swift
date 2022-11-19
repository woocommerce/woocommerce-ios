import Foundation

public class AnalyticsHubTimeRange {
    
    private let selectionType: SelectionType
    
    var timeRange: TimeRange {
        get {
            let currentDate = Date()
            return TimeRange(start: currentDate.startOfCurrentMonth(), end: currentDate)
        }
    }
    
    init(selectionType: SelectionType) {
        self.selectionType = selectionType
    }
    
    enum SelectionType {
        case today
        case weekToDate
        case monthToDate
        case yearToDate
    }
    
    struct TimeRange {
        let start: Date
        let end: Date
    }
}

extension Date {
    func startOfCurrentMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func startOfLastMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: startOfCurrentMonth())!
    }
    
    func startOfCurrentYear() -> Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
    }
    
    func startOfLastYear() -> Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
    }
}
