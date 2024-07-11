import Foundation
import Codegen

/// Represents data granularity for stats (e.g. day, week, month, year)
///
public enum StatGranularity: String, Codable, GeneratedFakeable {
    case day
    case week
    case month
    case year
}
