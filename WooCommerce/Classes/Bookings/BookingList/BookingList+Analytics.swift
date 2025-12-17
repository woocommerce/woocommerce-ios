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
    }
}

fileprivate extension WooAnalyticsEvent.BookingList {
    enum Properties {
        static let selectedTab = "selected_tab"
        static let isDefaultTab = "is_default_tab"
        static let isListEmpty = "is_list_empty"
        static let isFiltered = "is_filtered"
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
