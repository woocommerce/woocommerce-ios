extension WooAnalyticsEvent {
    enum BookingList {
        static func tabSelected(_ tab: BookingListTab) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListTabSelected,
                              properties: [Properties.selectedTab: tab.analyticsName])
        }
    }
}

fileprivate extension WooAnalyticsEvent.BookingList {
    enum Properties {
        static let selectedTab = "selected_tab"
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
