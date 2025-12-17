extension WooAnalyticsEvent {
    enum BookingList {
        static func tabSelected(_ tab: BookingListTab) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListTabSelected,
                              properties: [Properties.selectedTab: tab.analyticsName])
        }

        static func bookingListDisplayed(
            tab: BookingListTab,
            isDefaultTab: Bool,
            isListEmpty: Bool,
            isFiltered: Bool
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListDisplayed,
                              properties: [
                                Properties.selectedTab: tab.analyticsName,
                                Properties.isDefaultTab: isDefaultTab,
                                Properties.isListEmpty: isListEmpty,
                                Properties.isFiltered: isFiltered,
                              ])
        }

        static func failedToFetchBookings(_ error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListFailedToFetchBookings,
                              properties: error.analyticsProperties)

        }

        static func bookingTapped(selectedTab: BookingListTab,
                                  isSearchActive: Bool,
                                  isFilteringActive: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListBookingTapped,
                              properties: [
                                Properties.selectedTab: selectedTab.analyticsName,
                                Properties.isSearchActive: isSearchActive,
                                Properties.isFilteringActive: isFilteringActive,
                              ])
        }

        static func filtersTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListFiltersTapped)
        }

        static func applyFilters(_ filters: [Filter]) -> WooAnalyticsEvent {
            let properties = [
                Properties.selectedFilters: filters.map { $0.rawValue }.joined(separator: ",")
            ]
            return WooAnalyticsEvent(statName: .bookingListApplyFilters,
                                     properties: properties)
        }

        static func searchTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListSearchTapped)
        }
    }
}

fileprivate extension WooAnalyticsEvent.BookingList {
    enum Properties {
        static let selectedTab = "selected_tab"
        static let isDefaultTab = "is_default_tab"
        static let isListEmpty = "is_list_empty"
        static let isFiltered = "is_filtered"
        static let isSearchActive = "is_search_active"
        static let isFilteringActive = "is_filtering_active"
        static let selectedFilters = "selected_filters"
    }
}

fileprivate extension BookingListTab {
    var analyticsName: String {
        switch self {
        case .today: "today"
        case .upcoming: "upcoming"
        case .all: "all"
        }
    }
}

extension WooAnalyticsEvent.BookingList {
    enum Filter: String {
        case attendanceStatus = "attendance_status"
        case customer = "customer"
        case dateTime = "date_time"
        case serviceEvents = "service_events"
        case teamMember = "team_member"

    }
}
