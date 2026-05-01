import XCTest
@testable import WooCommerce

final class StoreInfoDataServiceTests: XCTestCase {
    private let timeZone = TimeZone(secondsFromGMT: 0)!

    func test_previousPeriod_whenRangeIsToday_thenReturnsYesterdayWindow() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let today = StoreInfoDataService.DateRange.today(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = today.previousPeriod()

        // Then
        XCTAssertEqual(previous.earliestDateToInclude, try makeDate(year: 2026, month: 4, day: 28, hour: 0, minute: 0, second: 0))
        XCTAssertEqual(previous.latestDateToInclude, try makeDate(year: 2026, month: 4, day: 28, hour: 23, minute: 59, second: 59))
        XCTAssertEqual(previous.orderStatsGranularity, today.orderStatsGranularity)
        XCTAssertEqual(previous.orderStatsQuantity, today.orderStatsQuantity)
        XCTAssertEqual(previous.summaryStatsPeriod, today.summaryStatsPeriod)
        XCTAssertEqual(previous.timezone, timeZone)
    }

    func test_previousPeriod_whenRangeIsLast7Days_thenReturnsPriorSevenDayWindow() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let last7Days = StoreInfoDataService.DateRange.last7Days(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = last7Days.previousPeriod()

        // Then
        XCTAssertEqual(previous.earliestDateToInclude, try makeDate(year: 2026, month: 4, day: 16, hour: 0, minute: 0, second: 0))
        XCTAssertEqual(previous.latestDateToInclude, try makeDate(year: 2026, month: 4, day: 22, hour: 23, minute: 59, second: 59))
        XCTAssertEqual(previous.orderStatsGranularity, last7Days.orderStatsGranularity)
        XCTAssertEqual(previous.orderStatsQuantity, last7Days.orderStatsQuantity)
        XCTAssertEqual(previous.summaryStatsPeriod, last7Days.summaryStatsPeriod)
        XCTAssertEqual(previous.timezone, timeZone)
    }

    func test_previousPeriod_whenRangeIsLast30Days_thenReturnsPriorThirtyDayWindow() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let last30Days = StoreInfoDataService.DateRange.last30Days(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = last30Days.previousPeriod()

        // Then
        XCTAssertEqual(previous.earliestDateToInclude, try makeDate(year: 2026, month: 3, day: 1, hour: 0, minute: 0, second: 0))
        XCTAssertEqual(previous.latestDateToInclude, try makeDate(year: 2026, month: 3, day: 30, hour: 23, minute: 59, second: 59))
        XCTAssertEqual(previous.orderStatsGranularity, last30Days.orderStatsGranularity)
        XCTAssertEqual(previous.orderStatsQuantity, last30Days.orderStatsQuantity)
        XCTAssertEqual(previous.summaryStatsPeriod, last30Days.summaryStatsPeriod)
        XCTAssertEqual(previous.timezone, timeZone)
    }

    func test_previousPeriod_whenRangeIsToday_thenIsContiguousWithCurrentPeriod() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let today = StoreInfoDataService.DateRange.today(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = today.previousPeriod()

        // Then — previous.latest is exactly one second before current.earliest
        let oneSecondAfter = previous.latestDateToInclude.addingTimeInterval(1)
        XCTAssertEqual(oneSecondAfter, today.earliestDateToInclude)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0, second: Int = 0) throws -> Date {
        var components = DateComponents()
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return try XCTUnwrap(Calendar(identifier: .gregorian).date(from: components))
    }
}
