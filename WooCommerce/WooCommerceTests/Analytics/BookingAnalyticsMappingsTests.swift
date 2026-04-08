import Foundation
import Testing
@testable import WooCommerce
import Yosemite

struct BookingAnalyticsMappingsTests {

    @Test func test_analyticsFilterString_returns_comma_separated_keys_for_active_filters() {
        // Given
        let noFilters = BookingFiltersViewModel.Filters()
        let allFilters = BookingFiltersViewModel.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 0, name: "")],
            products: [BookingProductFilter(productID: 0, name: "")],
            attendanceStatus: .attended,
            customers: [BookingCustomerFilter(customerID: 0, name: "")],
            dateRange: BookingDateRangeFilter(startDate: Date(), endDate: Date()),
            numberOfActiveFilters: 5
        )

        // Then
        #expect(noFilters.analyticsFilterString == "")
        #expect(allFilters.analyticsFilterString == "attendance_status,customer,date_time,service_events,team_member")
    }
}
