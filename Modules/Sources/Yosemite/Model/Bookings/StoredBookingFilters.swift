import Foundation
import Codegen

/// Models a dictionary of `siteID` and Booking Filters
/// These entities will be serialised to a plist file
///
public struct StoredBookingFilters: Codable, Equatable, GeneratedFakeable {

    /// SiteID: Booking Filters
    public let filters: [Int64: Filters]

    public init(filters: [Int64: Filters]) {
        self.filters = filters
    }

    public struct Filters: Codable, Equatable {
        public let teamMembers: [BookingTeamMemberFilter]
        public let products: [BookingProductFilter]
        public let attendanceStatus: BookingAttendanceStatus?
        public let customers: [BookingCustomerFilter]
        public let dateRange: BookingDateRangeFilter?
        public let numberOfActiveFilters: Int

        public init(teamMembers: [BookingTeamMemberFilter],
                    products: [BookingProductFilter],
                    attendanceStatus: BookingAttendanceStatus?,
                    customers: [BookingCustomerFilter],
                    dateRange: BookingDateRangeFilter?) {
            self.teamMembers = teamMembers
            self.products = products
            self.attendanceStatus = attendanceStatus
            self.customers = customers
            self.dateRange = dateRange
            self.numberOfActiveFilters = {
                var total = 0
                if teamMembers.isNotEmpty {
                    total += 1
                }
                if products.isNotEmpty {
                    total += 1
                }
                if attendanceStatus != nil {
                    total += 1
                }
                if customers.isNotEmpty {
                    total += 1
                }
                if dateRange != nil {
                    total += 1
                }

                return total
            }()
        }
    }
}
