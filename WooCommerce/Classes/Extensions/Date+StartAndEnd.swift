import Foundation

extension Date {
    // MARK: Day

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    // MARK: Week

    var startOfWeek: Date {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfDay)
        return Calendar.current.date(from: components)!
    }

    var endOfWeek: Date {
        return Calendar.current.date(byAdding: .second, value: 604799, to: startOfWeek)!
    }

    // MARK: Month

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }

    // MARK: Year

    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: startOfDay)
        return Calendar.current.date(from: components)!
    }

    var endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfYear)!
    }
}
