import XCTest
@testable import WooCommerce


/// Date+Woo: Unit Tests
///
final class DateWooTests: XCTestCase {

    func testUpdateStringWorksForIntervalsUnderTwoMinutes() {

        // 1 second
        let momentsAgo = NSLocalizedString("Updated moments ago",
                                           comment: "A unit test string for relative time intervals")
        let oneSecondAgo = Calendar.current.date(byAdding: .second, value: -1, to: Date())!
        XCTAssertEqual(oneSecondAgo.relativelyFormattedUpdateString, momentsAgo)

        // 12 seconds
        let twelveSecondsAgo = Calendar.current.date(byAdding: .second, value: -12, to: Date())!
        XCTAssertEqual(twelveSecondsAgo.relativelyFormattedUpdateString, momentsAgo)

        // 1 minute, 59 seconds
        let almostTwoMinutesAgo = Calendar.current.date(byAdding: .second, value: -119, to: Date())!
        XCTAssertEqual(almostTwoMinutesAgo.relativelyFormattedUpdateString, momentsAgo)

        // 2 minutes
        let twoMinutesAgo = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!
        XCTAssertNotEqual(twoMinutesAgo.relativelyFormattedUpdateString, momentsAgo)
    }

    func testUpdateStringWorksForIntervalsOneDayOrLess() {

        let minutesAgo = String.localizedStringWithFormat(
            NSLocalizedString("Updated %ld minutes ago",
                              comment: "A unit test string for time intervals"),
            2)

        let almostHourAgo = String.localizedStringWithFormat(
            NSLocalizedString("Updated %ld minutes ago",
                              comment: "A unit test string for a plural time interval in minutes"),
            59)

        let hourAgo = String.localizedStringWithFormat(
            NSLocalizedString("Updated %ld hour ago",
                              comment: "A unit test string for a singular time interval"),
            1)

        let nineAgo = String.localizedStringWithFormat(
            NSLocalizedString("Updated %ld hours ago",
                              comment: "A unit test string for a plural time interval in hours"),
            9)

        let almostDayAgo = String.localizedStringWithFormat(
            NSLocalizedString("Updated %ld hours ago",
                              comment: "A unit test string for time interval just under 1 day"),
            23)

        let dayAgo = String.localizedStringWithFormat(
            NSLocalizedString("Updated %ld hours ago",
                              comment: "A unit test string for 1 day, represented as plural time interval in hours"),
            24)

        // 2 minutes
        let twoMinutesAgo = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!

        XCTAssertEqual(twoMinutesAgo.relativelyFormattedUpdateString, minutesAgo)

        // 2 minutes, 3 seconds
        let twoPlusMinutesAgo = Calendar.current.date(byAdding: .second, value: -123, to: Date())!
        XCTAssertEqual(twoPlusMinutesAgo.relativelyFormattedUpdateString, minutesAgo)

        // 59 minutes
        let twoFiftyNineMinutesAgo = Calendar.current.date(byAdding: .minute, value: -59, to: Date())!
        XCTAssertEqual(twoFiftyNineMinutesAgo.relativelyFormattedUpdateString, almostHourAgo)

        // 1 hour
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        XCTAssertEqual(oneHourAgo.relativelyFormattedUpdateString, hourAgo)

        /// 9 hours
        let nineHoursAgo = Calendar.current.date(byAdding: .hour, value: -9, to: Date())!
        XCTAssertEqual(nineHoursAgo.relativelyFormattedUpdateString, nineAgo)

        /// 23 hours, 59 minutes
        let underOneDayAgo = Calendar.current.date(byAdding: .minute, value: -1439, to: Date())!
        XCTAssertEqual(underOneDayAgo.relativelyFormattedUpdateString, almostDayAgo)

        // 1 day
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertNotEqual(oneDayAgo.relativelyFormattedUpdateString, dayAgo)
    }

    func testUpdateStringWorksForIntervalsOverOneDay() {

        // Skip verifying the time part of the resulting string because of TZ madness

        // Oct 10,2018
        let dateComponents1 = DateComponents(calendar: Calendar.current, year: 2018, month: 10, day: 10)
        let specificPastDate1 = Calendar.current.date(from: dateComponents1)!
        let octDate = specificPastDate1.toString(dateStyle: .medium, timeStyle: .short)
        let updatedOct = NSLocalizedString("Updated on %@",
                                           comment: "Updated on <date>")
        let octExpected = String.localizedStringWithFormat(updatedOct, octDate)
        XCTAssertEqual(specificPastDate1.relativelyFormattedUpdateString, octExpected)

        // Feb 2, 2016
        let dateComponents2 = DateComponents(calendar: Calendar.current, year: 2016, month: 2, day: 2)
        let specificPastDate2 = Calendar.current.date(from: dateComponents2)!
        let febDate = specificPastDate2.toString(dateStyle: .medium, timeStyle: .short)
        let updatedFeb = NSLocalizedString("Updated on %@",
                                           comment: "Updated on <date>")
        let febExpected = String.localizedStringWithFormat(updatedFeb, febDate)
        XCTAssertEqual(specificPastDate2.relativelyFormattedUpdateString, febExpected)
    }

    func testUpdateStringWorksForFutureIntervals() {
        // Use the localized version of this saying
        let momentsAgo = NSLocalizedString("Updated moments ago",
                                           comment: "A unit test string for relative time intervals")

        // 1 second in future
        let futureDate = Calendar.current.date(byAdding: .second, value: 1, to: Date())!
        XCTAssertEqual(futureDate.relativelyFormattedUpdateString, momentsAgo)

        // 1 year in future
        let futureDate2 = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        XCTAssertEqual(futureDate2.relativelyFormattedUpdateString, momentsAgo)
    }

    func testIsSameYearReturnsTrueIfTheDatesAreFromTheSameYear() {
        let calendar = Calendar.current
        let thisDate: Date = {
            let components = DateComponents(calendar: calendar, year: 2018, month: 12, day: 25)
            return calendar.date(from: components)!
        }()
        let thatDate: Date = {
            let components = DateComponents(calendar: calendar, year: 2018, month: 1, day: 1)
            return calendar.date(from: components)!
        }()

        let isSameYear = thisDate.isSameYear(as: thatDate)

        XCTAssertTrue(isSameYear)
    }

    func testIsSameYearReturnsFalseIfTheDatesAreNotFromTheSameYear() {
        let calendar = Calendar.current
        let thisDate: Date = {
            let components = DateComponents(calendar: calendar, year: 2018, month: 12, day: 25)
            return calendar.date(from: components)!
        }()
        let thatDate: Date = {
            let components = DateComponents(calendar: calendar, year: 2019, month: 1, day: 1)
            return calendar.date(from: components)!
        }()

        let isSameYear = thisDate.isSameYear(as: thatDate)

        XCTAssertFalse(isSameYear)
    }

    /// For example, if Date() is 2020-01-01 01:00:00, then nextMidnight() should return
    /// 2020-01-02 00:00:00.
    func testNextMidnightMethodReturnsTomorrowWithoutTime() {
        // Given
        let formatter = DateFormatter.Defaults.iso8601
        let calendar: Calendar = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = formatter.timeZone
            return cal
        }()

        let fromDate = formatter.date(from: "2020-01-01T01:56:12Z")!

        // When
        let actual = fromDate.nextMidnight(using: calendar)

        // Then
        let expected = formatter.date(from: "2020-01-02T00:00:00Z")!
        XCTAssertEqual(actual, expected)
    }
}
