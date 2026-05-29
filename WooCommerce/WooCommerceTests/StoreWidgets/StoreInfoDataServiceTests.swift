@testable import WooCommerce
import Foundation
import Testing

struct StoreInfoDataServiceTests {
    private let timeZone = TimeZone(secondsFromGMT: 0)!

    // MARK: - previousPeriod() boundary math

    @Test func previousPeriod_whenRangeIsToday_thenReturnsYesterdayWindow() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let today = StoreInfoDataService.DateRange.today(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = today.previousPeriod()

        // Then
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 28, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 28, hour: 23, minute: 59, second: 59)))
        #expect(previous.orderStatsGranularity == today.orderStatsGranularity)
        #expect(previous.orderStatsQuantity == today.orderStatsQuantity)
        #expect(previous.summaryStatsPeriod == today.summaryStatsPeriod)
        #expect(previous.timezone == timeZone)
    }

    @Test func previousPeriod_whenRangeIsYesterday_thenReturnsDayBeforeYesterdayWindow() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let yesterday = StoreInfoDataService.DateRange.yesterday(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = yesterday.previousPeriod()

        // Then
        #expect(yesterday.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 28, hour: 0, minute: 0, second: 0)))
        #expect(yesterday.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 28, hour: 23, minute: 59, second: 59)))
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 27, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 27, hour: 23, minute: 59, second: 59)))
        #expect(previous.summaryStatsPeriod == .day)
    }

    @Test func previousPeriod_whenRangeIsLastWeek_thenReturnsWeekBefore() throws {
        // Given — Wed 29 Apr 2026
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let lastWeek = StoreInfoDataService.DateRange.lastWeek(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = lastWeek.previousPeriod()

        // Then — current = Apr 19 (Sun) … Apr 25 (Sat); previous = Apr 12 … Apr 18.
        #expect(lastWeek.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 19, hour: 0, minute: 0, second: 0)))
        #expect(lastWeek.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 25, hour: 23, minute: 59, second: 59)))
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 12, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 18, hour: 23, minute: 59, second: 59)))
        #expect(previous.summaryStatsPeriod == .week)
    }

    @Test func previousPeriod_whenRangeIsLastMonth_thenReturnsMonthBefore() throws {
        // Given — May 6, 2026
        let referenceDate = try makeDate(year: 2026, month: 5, day: 6, hour: 14)
        let lastMonth = StoreInfoDataService.DateRange.lastMonth(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = lastMonth.previousPeriod()

        // Then — current = April 1–30, 2026; previous = March 1–31, 2026.
        #expect(lastMonth.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 1, hour: 0, minute: 0, second: 0)))
        #expect(lastMonth.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 30, hour: 23, minute: 59, second: 59)))
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 3, day: 1, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 3, day: 31, hour: 23, minute: 59, second: 59)))
        #expect(previous.summaryStatsPeriod == .month)
    }

    @Test func previousPeriod_whenRangeIsWeekToDate_thenReturnsSameWindowOfPreviousWeek() throws {
        // Given — Wed 29 Apr 2026
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let weekToDate = StoreInfoDataService.DateRange.weekToDate(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = weekToDate.previousPeriod()

        // Then — current week extends to Sat May 2 (future-tolerant);
        // previous = start-of-last-week … same time-of-day 7 days back.
        #expect(weekToDate.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 26, hour: 0, minute: 0, second: 0)))
        #expect(weekToDate.latestDateToInclude == (try makeDate(year: 2026, month: 5, day: 2, hour: 23, minute: 59, second: 59)))
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 19, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 22, hour: 14, minute: 0, second: 0)))
        #expect(previous.summaryStatsPeriod == .week)
    }

    @Test func previousPeriod_whenRangeIsMonthToDate_thenReturnsSameWindowOfPreviousMonth() throws {
        // Given — May 6, 2026 14:00
        let referenceDate = try makeDate(year: 2026, month: 5, day: 6, hour: 14)
        let monthToDate = StoreInfoDataService.DateRange.monthToDate(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = monthToDate.previousPeriod()

        // Then — current = full May (future-tolerant); previous = Apr 1 … Apr 6 14:00.
        #expect(monthToDate.earliestDateToInclude == (try makeDate(year: 2026, month: 5, day: 1, hour: 0, minute: 0, second: 0)))
        #expect(monthToDate.latestDateToInclude == (try makeDate(year: 2026, month: 5, day: 31, hour: 23, minute: 59, second: 59)))
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 1, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 6, hour: 14, minute: 0, second: 0)))
        #expect(previous.summaryStatsPeriod == .month)
    }

    @Test func previousPeriod_whenHourlyRangeSpansMultipleDays_thenDerivesDurationFromBounds() throws {
        // Given
        let range = StoreInfoDataService.DateRange(
            orderStatsGranularity: .hourly,
            orderStatsQuantity: 48,
            earliestDateToInclude: try makeDate(year: 2026, month: 4, day: 28, hour: 0, minute: 0, second: 0),
            latestDateToInclude: try makeDate(year: 2026, month: 4, day: 29, hour: 23, minute: 59, second: 59),
            summaryStatsPeriod: .day,
            timezone: timeZone
        )

        // When
        let previous = range.previousPeriod()

        // Then
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 26, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 27, hour: 23, minute: 59, second: 59)))
        #expect(previous.orderStatsGranularity == range.orderStatsGranularity)
        #expect(previous.orderStatsQuantity == range.orderStatsQuantity)
        #expect(previous.summaryStatsPeriod == range.summaryStatsPeriod)
        #expect(previous.timezone == timeZone)
    }

    // MARK: - Contiguity invariant (period-aligned ranges only)
    // weekToDate / monthToDate intentionally leave a gap; not exercised here.

    @Test func previousPeriod_whenRangeIsToday_thenIsContiguousWithCurrentPeriod() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let today = StoreInfoDataService.DateRange.today(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = today.previousPeriod()

        // Then — previous.latest is exactly one second before current.earliest
        #expect(previous.latestDateToInclude.addingTimeInterval(1) == today.earliestDateToInclude)
    }

    @Test func previousPeriod_whenRangeIsLastWeek_thenIsContiguousWithCurrentPeriod() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let lastWeek = StoreInfoDataService.DateRange.lastWeek(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = lastWeek.previousPeriod()

        // Then
        #expect(previous.latestDateToInclude.addingTimeInterval(1) == lastWeek.earliestDateToInclude)
    }

    @Test func previousPeriod_whenRangeIsLastMonth_thenIsContiguousWithCurrentPeriod() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 5, day: 6, hour: 14)
        let lastMonth = StoreInfoDataService.DateRange.lastMonth(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = lastMonth.previousPeriod()

        // Then
        #expect(previous.latestDateToInclude.addingTimeInterval(1) == lastMonth.earliestDateToInclude)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0, second: Int = 0) throws -> Date {
        var components = DateComponents()
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return try #require(Calendar(identifier: .gregorian).date(from: components))
    }
}
