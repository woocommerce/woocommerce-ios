import Foundation
import enum Yosemite.StatsTimeRangeV4
import enum Yosemite.AnalyticsOrderDateType
import struct Yosemite.Site

extension WooAnalyticsEvent {
    enum Dashboard {
        /// Common event keys.
        private enum Keys {
            static let range = "range"
            static let localTimezone = "local_timezone"
            static let storeTimezone = "store_timezone"
            static let siteConnectionType = "site_connection_type"
            static let orderType = "order_type"
        }

        /// Tracked once per session when the site connection type is identified on the dashboard.
        /// - Parameter siteConnectionType: the type of connection for the site.
        static func siteConnectionTypeIdentified(siteConnectionType: SiteConnectionType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteConnectionTypeIdentified, properties: [
                Keys.siteConnectionType: siteConnectionType.analyticsValue
            ])
        }

        /// Tracked when the store stats are loaded with fresh data either via first load, event driven refresh, or manual refresh.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
        static func dashboardMainStatsLoaded(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsLoaded, properties: [Keys.range: timeRange.analyticsValue])
        }

        /// Tracked when the date range on the store stats view changes.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
        static func dashboardMainStatsDate(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsDate, properties: [Keys.range: timeRange.analyticsValue])
        }

        /// Tracked when the top performers are loaded with fresh data either via first load, event driven refresh, or manual refresh.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
        static func dashboardTopPerformersLoaded(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardTopPerformersLoaded, properties: [Keys.range: timeRange.analyticsValue])
        }

        /// Tracked when the date range on the top performers view changes.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
        static func dashboardTopPerformersDate(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardTopPerformersDate, properties: [Keys.range: timeRange.analyticsValue])
        }

        /// Tracked when the dashboard is accessed with a device timezone different from the store timezone.
        /// - Parameter localTimezone: The current timezone offset in hours of the device running the app.
        /// - Parameter storeTimezone: The store timezone offset in hours defined by the API.
        static func dashboardTimezonesDiffers(localTimezone: Double, storeTimezone: Double) -> WooAnalyticsEvent {
            let localTimezoneText = String(format: "%g", localTimezone)
            let storeTimezoneText = String(format: "%g", storeTimezone)
            return WooAnalyticsEvent(statName: .dashboardStoreTimezoneDifferFromDevice,
                                     properties: [Keys.storeTimezone: storeTimezoneText,
                                                  Keys.localTimezone: localTimezoneText])
        }

        // MARK: Order type bottom sheet

        /// Tracked when the merchant taps the chevron next to the order type label on the Performance card.
        static func performanceCardOrderTypeChevronTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsOrderTypeChevronTapped, properties: [:])
        }

        /// Tracked when the merchant selects an order type from the bottom sheet.
        /// - Parameter orderType: The selected order type.
        static func performanceCardOrderTypeSelected(_ orderType: AnalyticsOrderDateType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsOrderTypeSelected,
                              properties: [Keys.orderType: orderType.analyticsValue])
        }

        /// Tracked when updating the order type setting fails.
        /// - Parameter error: The error reported by the data layer.
        static func performanceCardOrderTypeUpdateFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsOrderTypeUpdateFailed,
                              properties: [:],
                              error: error)
        }
    }
}

private extension AnalyticsOrderDateType {
    var analyticsValue: String {
        switch self {
        case .paid:
            return "paid"
        case .allOrders:
            return "all_orders"
        case .completed:
            return "completed"
        }
    }
}

private extension StatsTimeRangeV4 {
    var analyticsValue: String {
        switch self {
        case .today:
            return "days"
        case .thisWeek:
            return "weeks"
        case .thisMonth:
            return "months"
        case .thisYear:
            return "years"
        case .custom:
            return "custom"
        }
    }
}

/// The type of connection for a site, for analytics purposes.
enum SiteConnectionType {
    /// Site is not connected to Jetpack
    case nonJetpack
    /// Site is connected via Jetpack Connection Package (not the full plugin)
    case jetpackConnectionPackage
    /// Site has the full Jetpack plugin installed and connected
    case fullJetpack
    /// Unknown connection type
    case unknown

    /// Creates a `SiteConnectionType` from a `Site`.
    init(site: Site?) {
        guard let site else {
            self = .unknown
            return
        }

        if !site.isJetpackConnected {
            self = .nonJetpack
        } else if site.isJetpackCPConnected {
            self = .jetpackConnectionPackage
        } else if site.isJetpackThePluginInstalled {
            self = .fullJetpack
        } else {
            self = .unknown
        }
    }

    var analyticsValue: String {
        switch self {
        case .nonJetpack:
            return "non_jetpack"
        case .jetpackConnectionPackage:
            return "jetpack_connection_package"
        case .fullJetpack:
            return "full_jetpack"
        case .unknown:
            return "unknown"
        }
    }
}
