import Foundation

/// Represents a marketing event that merchants can schedule actions for
struct MarketingEvent: Identifiable, Equatable {
    let id: String
    let name: String
    let date: Date
    let type: EventType

    enum EventType: String, CaseIterable {
        case blackFriday = "black_friday"
        case holidaySale = "holiday_sale"
        case custom = "custom"

        var displayName: String {
            switch self {
            case .blackFriday:
                return NSLocalizedString(
                    "marketingEvent.blackFriday",
                    value: "Black Friday",
                    comment: "Name for Black Friday marketing event"
                )
            case .holidaySale:
                return NSLocalizedString(
                    "marketingEvent.holidaySale",
                    value: "Holiday Sale",
                    comment: "Name for Holiday Sale marketing event"
                )
            case .custom:
                return NSLocalizedString(
                    "marketingEvent.custom",
                    value: "Custom Event",
                    comment: "Name for custom marketing event"
                )
            }
        }

        var iconName: String {
            switch self {
            case .blackFriday:
                return "tag.fill"
            case .holidaySale:
                return "gift.fill"
            case .custom:
                return "calendar.badge.plus"
            }
        }
    }

    /// Creates preset marketing events for a given year (initially empty)
    static func presetEvents(for year: Int) -> [MarketingEvent] {
        return []
    }

    /// Suggested marketing events for a given year
    static func suggestedEvents(for year: Int) -> [MarketingEvent] {
        let calendar = Calendar.current

        // Black Friday (4th Friday of November)
        let blackFridayDate = DateHelper.blackFriday(year: year) ?? Date()

        // Holiday Sale (December 15th as example)
        var holidayComponents = DateComponents()
        holidayComponents.year = year
        holidayComponents.month = 12
        holidayComponents.day = 15
        let holidayDate = calendar.date(from: holidayComponents) ?? Date()

        return [
            MarketingEvent(
                id: "black-friday-\(year)",
                name: "Black Friday \(year)",
                date: blackFridayDate,
                type: .blackFriday
            ),
            MarketingEvent(
                id: "holiday-sale-\(year)",
                name: "Holiday Sale \(year)",
                date: holidayDate,
                type: .holidaySale
            )
        ]
    }
}

private enum DateHelper {
    /// Calculates Black Friday (day after 4th Thursday of November)
    static func blackFriday(year: Int) -> Date? {
        let calendar = Calendar.current

        // Find all Fridays in November
        var components = DateComponents()
        components.year = year
        components.month = 11 // November
        components.weekday = 6 // Friday

        guard let novemberFirst = calendar.date(from: DateComponents(year: year, month: 11, day: 1)) else {
            return nil
        }

        // Get the range of the month
        guard let range = calendar.range(of: .day, in: .month, for: novemberFirst) else {
            return nil
        }

        // Find all Fridays in November
        var fridays: [Date] = []
        for day in range {
            var dayComponents = DateComponents()
            dayComponents.year = year
            dayComponents.month = 11
            dayComponents.day = day

            if let date = calendar.date(from: dayComponents),
               calendar.component(.weekday, from: date) == 6 { // Friday
                fridays.append(date)
            }
        }

        // Black Friday is the 4th Friday of November
        return fridays.count >= 4 ? fridays[3] : fridays.last
    }
}
