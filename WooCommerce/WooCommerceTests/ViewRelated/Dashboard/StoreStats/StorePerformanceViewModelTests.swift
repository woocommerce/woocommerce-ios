import XCTest
import Yosemite
@testable import WooCommerce

final class StorePerformanceViewModelTests: XCTestCase {

    func test_dates_for_custom_range_are_correct_for_non_custom_time_range() throws {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        viewModel.didSelectTimeRange(.thisWeek)

        // Then
        let now = Date()
        let startDateForCustomRange = viewModel.startDateForCustomRange
        let endDateForCustomRange = viewModel.endDateForCustomRange
        XCTAssertTrue(now.isSameDay(as: endDateForCustomRange))
        XCTAssertTrue(try XCTUnwrap(now.adding(days: -30)).isSameDay(as: startDateForCustomRange))
    }

    func test_dates_for_custom_range_are_correct_for_custom_time_range() throws {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        let startDate = try XCTUnwrap(Date().adding(days: -100))
        let endDate = try XCTUnwrap(Date().adding(days: -10))
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))

        // Then
        XCTAssertEqual(viewModel.startDateForCustomRange, startDate)
        XCTAssertEqual(viewModel.endDateForCustomRange, endDate)
    }
}
