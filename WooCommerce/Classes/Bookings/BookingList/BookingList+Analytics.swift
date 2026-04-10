extension WooAnalyticsEvent {
    enum BookingList {
        static func tabSelect(_ tab: BookingListTab) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListTabSelect,
                              properties: [Properties.selectedTab: tab.analyticsName])
        }

        static func bookingListView(
            tab: BookingListTab,
            isDefaultTab: Bool,
            isListEmpty: Bool,
            isFiltered: Bool
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListView,
                              properties: [
                                Properties.selectedTab: tab.analyticsName,
                                Properties.isDefaultTab: isDefaultTab,
                                Properties.isListEmpty: isListEmpty,
                                Properties.isFiltered: isFiltered,
                              ])
        }

        static func failedToFetchBookings(_ error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListFailedToFetchBookings,
                              error: error)

        }

        static func bookingTap(selectedTab: BookingListTab,
                                isSearchActive: Bool,
                                isFilteringActive: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListBookingTap,
                              properties: [
                                Properties.selectedTab: selectedTab.analyticsName,
                                Properties.isSearchActive: isSearchActive,
                                Properties.isFilteringActive: isFilteringActive,
                              ])
        }

        static func filtersTap() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListFiltersTap)
        }

        static func applyFilters(_ filters: BookingFiltersViewModel.Filters) -> WooAnalyticsEvent {
            var appliedFilters = [WooAnalyticsEvent.BookingList.Filter]()
            if filters.attendanceStatus != nil {
                appliedFilters.append(.attendanceStatus)
            }
            if filters.bookingFilters.customerIDs.isNotEmpty {
                appliedFilters.append(.customer)
            }
            if filters.dateRange != nil {
                appliedFilters.append(.dateTime)
            }
            if filters.products.isNotEmpty {
                appliedFilters.append(.serviceEvents)
            }
            if filters.teamMembers.isNotEmpty {
                appliedFilters.append(.teamMember)
            }
            let properties = [
                Properties.selectedFilters: appliedFilters.map { $0.rawValue }.joined(separator: ",")
            ]
            return WooAnalyticsEvent(statName: .bookingListApplyFilters,
                                     properties: properties)
        }

        static func searchTap() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListSearchTap)
        }

        static func sortByTap() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListSortByTap)
        }

        static func sortByOptionTap(_ option: BookingListViewModel.SortBy) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListSortByOptionTap,
                              properties: [Properties.sortOption: option.analyticsName])
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
        static let sortOption = "sort_option"
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

fileprivate extension BookingListViewModel.SortBy {
    var analyticsName: String {
        switch self {
        case .newestToOldest: "newest_first"
        case .oldestToNewest: "oldest_first"
        }
    }
}
