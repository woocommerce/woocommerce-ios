import Foundation
import WooFoundation

private struct CodableCacheEntry<T: Codable>: Codable {
    let timestamp: Date
    let value: T
    let timeToLive: TimeInterval

    init(value: T, timeToLive: TimeInterval) {
        self.timestamp = .now
        self.value = value
        self.timeToLive = timeToLive
    }

    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < timeToLive
    }
}

/// Encapsulates the logic to cache Analytics Stats `Codable` objects tied to a site and a Date range
struct CodableStatsCache {
    static func loadValue<T: Codable>(from range: ClosedRange<Date>, siteID: Int64) -> T? {
        let userCache = SiteCodablePersistentCache<CodableCacheEntry<T>>(siteID: siteID, directoryName: String(describing: T.self))
        let key = range.cacheKey

        guard let entry = try? userCache.load(forKey: key) else {
            return nil
        }

        guard entry.isValid else {
            userCache.remove(forKey: key)

            return nil
        }

        return entry.value
    }

    static func save<T: Codable>(value: T,
                                 range: ClosedRange<Date>,
                                 siteID: Int64,
                                 timeToLive: TimeInterval) {
        debugPrint("saving value", value)
        let userCache = SiteCodablePersistentCache<CodableCacheEntry<T>>(siteID: siteID, directoryName: String(describing: TopEarnerStats.self))
        userCache.save(CodableCacheEntry(value: value, timeToLive: timeToLive), forKey: range.cacheKey)
    }
}

private extension ClosedRange<Date> {
    var cacheKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd:MM:yy"

        return dateFormatter.string(from: lowerBound) + "-" + dateFormatter.string(from: upperBound)
    }
}
