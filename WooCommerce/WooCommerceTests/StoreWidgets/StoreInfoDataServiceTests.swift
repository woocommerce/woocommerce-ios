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

    @Test func previousPeriod_whenRangeIsLast7Days_thenReturnsPriorSevenDayWindow() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let last7Days = StoreInfoDataService.DateRange.last7Days(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = last7Days.previousPeriod()

        // Then
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 4, day: 16, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 4, day: 22, hour: 23, minute: 59, second: 59)))
        #expect(previous.orderStatsGranularity == last7Days.orderStatsGranularity)
        #expect(previous.orderStatsQuantity == last7Days.orderStatsQuantity)
        #expect(previous.summaryStatsPeriod == last7Days.summaryStatsPeriod)
        #expect(previous.timezone == timeZone)
    }

    @Test func previousPeriod_whenRangeIsLast30Days_thenReturnsPriorThirtyDayWindow() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let last30Days = StoreInfoDataService.DateRange.last30Days(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = last30Days.previousPeriod()

        // Then
        #expect(previous.earliestDateToInclude == (try makeDate(year: 2026, month: 3, day: 1, hour: 0, minute: 0, second: 0)))
        #expect(previous.latestDateToInclude == (try makeDate(year: 2026, month: 3, day: 30, hour: 23, minute: 59, second: 59)))
        #expect(previous.orderStatsGranularity == last30Days.orderStatsGranularity)
        #expect(previous.orderStatsQuantity == last30Days.orderStatsQuantity)
        #expect(previous.summaryStatsPeriod == last30Days.summaryStatsPeriod)
        #expect(previous.timezone == timeZone)
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

    // MARK: - Contiguity invariant

    @Test func previousPeriod_whenRangeIsToday_thenIsContiguousWithCurrentPeriod() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let today = StoreInfoDataService.DateRange.today(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = today.previousPeriod()

        // Then — previous.latest is exactly one second before current.earliest
        #expect(previous.latestDateToInclude.addingTimeInterval(1) == today.earliestDateToInclude)
    }

    @Test func previousPeriod_whenRangeIsLast7Days_thenIsContiguousWithCurrentPeriod() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let last7Days = StoreInfoDataService.DateRange.last7Days(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = last7Days.previousPeriod()

        // Then
        #expect(previous.latestDateToInclude.addingTimeInterval(1) == last7Days.earliestDateToInclude)
    }

    @Test func previousPeriod_whenRangeIsLast30Days_thenIsContiguousWithCurrentPeriod() throws {
        // Given
        let referenceDate = try makeDate(year: 2026, month: 4, day: 29, hour: 14)
        let last30Days = StoreInfoDataService.DateRange.last30Days(referenceDate: referenceDate, timezone: timeZone)

        // When
        let previous = last30Days.previousPeriod()

        // Then
        #expect(previous.latestDateToInclude.addingTimeInterval(1) == last30Days.earliestDateToInclude)
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
