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
        public let customerFilter: CustomerFilter?

        public init(siteID: Int64,
                    orderStatusesFilter: [OrderStatusEnum]?,
                    dateRangeFilter: OrderDateRangeFilter?,
                    customerFilter: CustomerFilter?
        ) {
            self.siteID = siteID
            self.orderStatusesFilter = orderStatusesFilter
            self.dateRangeFilter = dateRangeFilter
            self.customerFilter = customerFilter
        }

        public func numberOfActiveFilters() -> Int {
            var total = 0
            if let orderStatusesFilter = orderStatusesFilter, orderStatusesFilter.count > 0 {
                total += 1
            }
            if let dateRangeFilter = dateRangeFilter, dateRangeFilter.filter != .any {
                total += 1
            }
            if let _ = customerFilter {
                total += 1
            }

            return total
        }



        enum CodingKeys: String, CodingKey {
            case siteID = "site_id"
            case orderStatusesFilter = "order_statuses_filter"
            case dateRangeFilter = "date_range_filter"
            case customerFilter = "customer_filter"
        }
    }

    /// SiteID: Setting
    public let settings: [Int64: Setting]

    public init(settings: [Int64: Setting]) {
        self.settings = settings
    }
}

public struct CustomerFilter: Codable, Hashable {
    public let id: Int64
}
