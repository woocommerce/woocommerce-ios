import Combine
import Foundation
import Testing
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import YosemiteTestHelpers
@testable import WooCommerce
@testable import Networking

@MainActor
class BookingListContainerViewModelTests {

    private let site = Site.fake()
    private let analyticsProvider = MockAnalyticsProvider()
    private lazy var analytics: WooAnalytics = WooAnalytics(analyticsProvider: self.analyticsProvider)
    private var storageManager: StorageManagerType = MockStorageManager()
    private lazy var storage: StorageType = {
        storageManager.viewStorage
    }()

    @Test func event_fire_when_default_tab_selected() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.setSelectedTab(to: .today)

        // Then
        #expect(analyticsProvider.received(event: "booking_list_tab_select",
                                         with: ["selected_tab": "today"]))
        #expect(analyticsProvider.received(event: "booking_list_view",
                                           with: [
                                            "selected_tab": "today",
                                            "is_default_tab": true,
                                            "is_list_empty": true,
                                            "is_filtered": false
                                           ]))
    }

    @Test func event_fire_when_nonDefault_tab_selected() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.setSelectedTab(to: .all)

        // Then
        #expect(analyticsProvider.received(event: "booking_list_tab_select",
                                         with: ["selected_tab": "all"]))
        #expect(analyticsProvider.received(event: "booking_list_view",
                                           with: [
                                            "selected_tab": "all",
                                            "is_default_tab": false,
                                            "is_list_empty": true,
                                            "is_filtered": false
                                           ]))
    }

    @Test func event_fire_when_onAppear() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.onAppear()

        // Then
        #expect(analyticsProvider.received(event: "booking_list_view",
                                           with: [
                                            "selected_tab": "today",
                                            "is_default_tab": true,
                                            "is_list_empty": true,
                                            "is_filtered": false
                                           ]))
    }

    @Test func event_fire_when_selectedBookingChanged() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.selectedBookingChanged()

        // Then
        #expect(analyticsProvider.received(
            event: "booking_list_booking_tap",
            with: [
                "selected_tab": "today",
                "is_search_active": false,
                "is_filtering_active": false
            ]))
    }

    @Test func event_fire_when_filtersTapped() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.filtersTapped()

        // Then
        #expect(analyticsProvider.received(event: "booking_list_filters_tap"))
    }

    @Test func event_fire_when_applyFiltersTapped() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.applyFiltersTapped()

        // Then
        #expect(analyticsProvider.received(
            event: "booking_list_apply_filters",
            with: ["selected_filters": ""]))
    }

    @Test func event_fire_when_applyFiltersTapped_withFilters() {
        // Given
        let viewModel = givenViewModel()

        // When
        let filters = BookingFiltersViewModel.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 0, name: "")],
            products: [BookingProductFilter(productID: 0, name: "")],
            attendanceStatus: .attended,
            customers: [BookingCustomerFilter(customerID: 0, name: "")],
            dateRange: BookingDateRangeFilter(startDate: Date(), endDate: Date()),
            numberOfActiveFilters: 5
        )
        viewModel.setSelectedTab(to: .all)
        viewModel.updateFilters(filters)
        viewModel.applyFiltersTapped()

        // Then
        #expect(analyticsProvider.received(
            event: "booking_list_apply_filters",
            with: ["selected_filters": "attendance_status,customer,date_time,service_events,team_member"]))
    }

    @Test func event_fire_when_searchTapped() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.searchTapped()

        // Then
        #expect(analyticsProvider.received(event: "booking_list_search_tap"))
    }

    @Test func event_fire_when_sortByTapped() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.sortByTapped()

        // Then
        #expect(analyticsProvider.received(event: "booking_list_sort_by_tap"))
    }

    // MARK: - Filter propagation

    @Test func updateFilters_propagates_to_all_tabs() {
        // Given
        let viewModel = givenViewModel()
        let filters = BookingFiltersViewModel.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 1, name: "Alice")],
            products: [],
            attendanceStatus: nil,
            customers: [],
            dateRange: nil,
            numberOfActiveFilters: 1
        )

        // When - on Today tab
        viewModel.setSelectedTab(to: .today)
        viewModel.updateFilters(filters)

        // Then - should propagate (no guard blocking non-All tabs)
        #expect(viewModel.numberOfActiveFilters == 1)
        #expect(viewModel.listViewModel(for: .today).hasFilters == true)
        #expect(viewModel.listViewModel(for: .upcoming).hasFilters == true)
        #expect(viewModel.listViewModel(for: .all).hasFilters == true)
    }

    @Test func clearFilters_works_on_non_all_tabs() {
        // Given
        let viewModel = givenViewModel()
        let filters = BookingFiltersViewModel.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 1, name: "Alice")],
            products: [],
            attendanceStatus: nil,
            customers: [],
            dateRange: nil,
            numberOfActiveFilters: 1
        )

        // Apply filters on Today tab
        viewModel.setSelectedTab(to: .today)
        viewModel.updateFilters(filters)
        #expect(viewModel.numberOfActiveFilters == 1)

        // When - clear filters on Today tab
        viewModel.clearFilters()

        // Then
        #expect(viewModel.numberOfActiveFilters == 0)
        #expect(viewModel.listViewModel(for: .today).hasFilters == false)
    }

    @Test func event_fire_when_sortByOptionSelected() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.sortByOptionSelected(.newestToOldest)

        // Then
        #expect(analyticsProvider.received(event: "booking_list_sort_by_option_tap",
                                           with: ["sort_option": "newest_first"]))
    }
}

fileprivate extension BookingListContainerViewModelTests {
    func givenViewModel() -> BookingListContainerViewModel {
        return BookingListContainerViewModel(
            siteID: site.siteID,
            stores: MockStoresManager(sessionManager: .testingInstance),
            analytics: analytics
        )
    }
}
