import Foundation
import WordPressShared

public struct StatsSubscribersSummaryData: Decodable, Equatable {
    public let history: [SubscriberData]

    public init(history: [SubscriberData]) {
        self.history = history
    }
}

extension StatsSubscribersSummaryData {
    public static var pathComponent: String {
        return "stats/subscribers"
    }

    static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POS")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    public struct SubscriberData: Decodable, Equatable {
        public let date: Date
        public let count: Int

        public init(date: Date, count: Int) {
            self.date = date
            self.count = count
        }
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let fields = jsonDictionary["fields"] as? [String],
            let data = jsonDictionary["data"] as? [[Any]],
            let dateIndex = fields.firstIndex(of: "period"),
            let countIndex = fields.firstIndex(of: "subscribers")
        else {
            return nil
        }

        let history: [SubscriberData?] = data.map { elements in
            guard elements.indices.contains(dateIndex) && elements.indices.contains(countIndex),
                let dateString = elements[dateIndex] as? String,
                let date = StatsSubscribersSummaryData.dateFormatter.date(from: dateString),
                let count = elements[countIndex] as? Int
            else {
                return nil
            }

            return SubscriberData(date: date, count: count)
        }

        let sorted = history.compactMap { $0 }.sorted(by: { $0.date.compare($1.date) == .orderedAscending })
        self = .init(history: sorted)
    }

    public static func queryProperties(quantity: Int, unit: StatsSubscribersSummaryData.Unit) -> [String: String] {
        return ["quantity": String(quantity), "unit": unit.rawValue]
    }

    public enum Unit: String {
        case day = "day"
    }
}
