import protocol WooFoundationCore.WooAnalyticsEventPropertyType

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

        static func failedToUpdateBookingDetails(action: Action, error: Error) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Properties.action: action.rawValue
            ]
            properties += error.analyticsProperties
            return  WooAnalyticsEvent(statName: .bookingListFailedToFetchBookings,
                                      properties: properties)
        }
    }
}

fileprivate extension WooAnalyticsEvent.BookingList {
    enum Properties {
        static let selectedTab = "selected_tab"
        static let isDefaultTab = "is_default_tab"
        static let isListEmpty = "is_list_empty"
        static let isFiltered = "is_filtered"
        static let action = "action"
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
    enum Action: String {
        case cancelBooking = "cancel_booking"
        case updateAttendance = "update_attendance"
        case markAsPaid = "mark_as_paid"
    }
}
