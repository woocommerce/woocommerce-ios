import Foundation
import WordPressShared

public struct StatsSubscribersSummaryData: Decodable, Equatable {
    let history: [SubscriberData]

    private enum CodingKeys: String, CodingKey {
        case history = "data"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        history = try container.decode([SubscriberData].self, forKey: .history)
    }

    public struct SubscriberData: Decodable, Equatable {
        let date: Date
        let count: Int

        private enum CodingKeys: Int, CodingKey {
            case date = 0
            case count = 1
        }

        public init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()

            date = ISO8601DateFormatter().date(from: try container.decode(String.self)) ?? Date()
            count = try container.decode(Int.self)
        }
    }
}

extension StatsSubscribersSummaryData {
    public static var pathComponent: String {
        return "stats/subscribers"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
            let decoder = JSONDecoder.apiDecoder
            self = try decoder.decode(Self.self, from: jsonData)
        } catch {
            return nil
        }
    }

    public static func queryProperties(quantity: Int, unit: String) -> [String: String] {
        return ["quantity": String(quantity), "unit": unit]
    }
}
