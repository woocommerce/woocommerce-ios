import XCTest
@testable import WooCommerce

final class StatsTimeRangeBarViewModelTests: XCTestCase {

    // MARK: - Legacy (`myStoreTabUpdates` feature flag disabled)

    func test_today_text_with_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let startDate = Date(timeIntervalSince1970: 1565892875)
        // GMT: Friday, August 16, 2019 2:14:35 AM
        let endDate = Date(timeIntervalSince1970: 1565921675)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .today,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_today_text_with_selected_date_and_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let startDate = Date(timeIntervalSince1970: 1565892875)
        // GMT: Friday, August 16, 2019 2:14:35 AM
        let endDate = Date(timeIntervalSince1970: 1565921675)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .today,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        formatter.timeZone = timezone
        let timeRangeString = formatter.string(from: startDate)

        let selectedDateFormatter = DateFormatter()
        selectedDateFormatter.setLocalizedDateFormatFromTemplate("ha")
        selectedDateFormatter.timeZone = timezone
        let selectedDateString = selectedDateFormatter.string(from: startDate)

        let dateBreadcrumbFormat = NSLocalizedString("%1$@ › %2$@", comment: "Displays a time range followed by a specific date/time")
        let expectedText = String.localizedStringWithFormat(dateBreadcrumbFormat, timeRangeString, selectedDateString)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisWeek_text_with_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisWeek,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        let expectedText = String.localizedStringWithFormat(NSLocalizedString("%1$@-%2$@", comment: "Displays a date range for a stats interval"),
                                                            formatter.string(from: startDate),
                                                            formatter.string(from: endDate))
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisWeek_text_with_selected_date_and_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .thisWeek,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate) // "Jul 28" in en-US locale.
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisMonth_text_with_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisMonth,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisMonth_text_with_selected_date_and_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .thisMonth,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate) // "Jul 28" in en-US locale.
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisYear_text_with_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisYear,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisYear_text_with_selected_date_and_myStoreTabUpdates_feature_disabled() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .thisYear,
                                                   timezone: timezone,
                                                   isMyStoreTabUpdatesEnabled: false)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        formatter.timeZone = timezone
        let timeRangeString = formatter.string(from: startDate)

        let selectedDateFormatter = DateFormatter()
        selectedDateFormatter.setLocalizedDateFormatFromTemplate("MMMM")
        selectedDateFormatter.timeZone = timezone
        let selectedDateString = selectedDateFormatter.string(from: startDate)

        let dateBreadcrumbFormat = NSLocalizedString("%1$@ › %2$@", comment: "Displays a time range followed by a specific date/time")
        // "2019 › July" in en-US locale.
        let expectedText = String.localizedStringWithFormat(dateBreadcrumbFormat, timeRangeString, selectedDateString)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }
}
