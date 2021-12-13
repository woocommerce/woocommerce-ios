import Foundation
import Codegen

/// Models a pair of `siteID` and Order Settings
/// These entities will be serialised to a plist file using `AppSettingsStore`
///
public struct StoredOrderSettings: Codable, Equatable {

    public struct Setting: Codable, Equatable {
        public let siteID: Int64
        public let orderStatusesFilter: [OrderStatusEnum]?
        public let dateRangeFilter: OrderDateRangeFilter?

        public init(siteID: Int64,
                    orderStatusesFilter: [OrderStatusEnum]?,
                    dateRangeFilter: OrderDateRangeFilter?) {
            self.siteID = siteID
            self.orderStatusesFilter = orderStatusesFilter
            self.dateRangeFilter = dateRangeFilter
        }

        public func numberOfActiveFilters() -> Int {
            var total = 0
            if let orderStatusesFilter = orderStatusesFilter, orderStatusesFilter.count > 0 {
                total += 1
            }
            if let dateRangeFilter = dateRangeFilter, dateRangeFilter.filter != .any {
                total += 1
            }

            return total
        }



        enum CodingKeys: String, CodingKey {
            case siteID = "site_id"
            case orderStatusesFilter = "order_statuses_filter"
            case dateRangeFilter = "date_range_filter"
        }
    }

    /// SiteID: Setting
    public let settings: [Int64: Setting]

    public init(settings: [Int64: Setting]) {
        self.settings = settings
    }
}
