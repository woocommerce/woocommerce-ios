// periphery:ignore:all - will be used for booking filters
import Foundation

/// Used to filter bookings by date range
///
public struct BookingDateRangeFilter: Codable, Equatable, Hashable {
    /// Start date of the range (inclusive)
    ///
    public let startDate: Date?

    /// End date of the range (inclusive)
    ///
    public let endDate: Date?

    public init(startDate: Date? = nil,
                endDate: Date? = nil) {
        self.startDate = startDate
        self.endDate = endDate
    }

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
    }
}
