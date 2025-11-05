import Foundation
import Codegen

/// Models a dictionary of `siteID` and Booking Filters
/// These entities will be serialised to a plist file
///
public struct StoredBookingFilters: Codable, Equatable, GeneratedFakeable {

    /// SiteID: BookingFilters
    public let filters: [Int64: BookingFilters]

    public init(filters: [Int64: BookingFilters]) {
        self.filters = filters
    }
}
