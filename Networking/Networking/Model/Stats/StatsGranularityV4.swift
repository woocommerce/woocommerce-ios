import Foundation

/// Represents data granularity for stats v4 (e.g. hour, day, week, month, year)
///
public enum StatsGranularityV4: String, Decodable, GeneratedFakeable {
    case hourly = "hour"
    case daily = "day"
    case weekly = "week"
    case monthly = "month"
    case yearly = "year"
}
