import Foundation

/// Represents data granularity for stats v4 (e.g. hour, day, week, month, year)
///
public enum StatsGranularityV4: String, Decodable {
    case hourly
    case daily
    case weekly
    case monthly
    case yearly
}
