import XCTest
@testable import WooCommerce


/// Date+Woo: Unit Tests
///
final class DateWooTests: XCTestCase {

    func testUpdateStringWorksForIntervalsUnderTwoMinutes() {

        // 1 second
        let oneSecondAgo = Calendar.current.date(byAdding: .second, value: -1, to: Date())!
        XCTAssertEqual(oneSecondAgo.relativelyFormattedUpdateString, "Updated moments ago")

        // 12 seconds
        let twelveSecondsAgo = Calendar.current.date(byAdding: .second, value: -12, to: Date())!
        XCTAssertEqual(twelveSecondsAgo.relativelyFormattedUpdateString, "Updated moments ago")

        // 1 minute, 59 seconds
        let almostTwoMinutesAgo = Calendar.current.date(byAdding: .second, value: -119, to: Date())!
        XCTAssertEqual(almostTwoMinutesAgo.relativelyFormattedUpdateString, "Updated moments ago")

        // 2 minutes
        let twoMinutesAgo = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!
        XCTAssertNotEqual(twoMinutesAgo.relativelyFormattedUpdateString, "Updated moments ago")
    }

    func testUpdateStringWorksForIntervalsOneDayOrLess() {

        // 2 minutes
        let twoMinutesAgo = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!
        XCTAssertEqual(twoMinutesAgo.relativelyFormattedUpdateString, "Updated 2 minutes ago")

        // 2 minutes, 3 seconds
        let twoPlusMinutesAgo = Calendar.current.date(byAdding: .second, value: -123, to: Date())!
        XCTAssertEqual(twoPlusMinutesAgo.relativelyFormattedUpdateString, "Updated 2 minutes ago")

        // 59 minutes
        let twoFiftyNineMinutesAgo = Calendar.current.date(byAdding: .minute, value: -59, to: Date())!
        XCTAssertEqual(twoFiftyNineMinutesAgo.relativelyFormattedUpdateString, "Updated 59 minutes ago")

        // 1 hour
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        XCTAssertEqual(oneHourAgo.relativelyFormattedUpdateString, "Updated 1 hour ago")

        /// 9 hours
        let nineHoursAgo = Calendar.current.date(byAdding: .hour, value: -9, to: Date())!
        XCTAssertEqual(nineHoursAgo.relativelyFormattedUpdateString, "Updated 9 hours ago")

        /// 23 hours, 59 minutes
        let underOneDayAgo = Calendar.current.date(byAdding: .minute, value: -1439, to: Date())!
        XCTAssertEqual(underOneDayAgo.relativelyFormattedUpdateString, "Updated 23 hours ago")

        // 1 day
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertNotEqual(oneDayAgo.relativelyFormattedUpdateString, "Updated 24 hours ago")
    }

    func testUpdateStringWorksForIntervalsOverOneDay() {

        // Skip verifying the time part of the resulting string because of TZ madness

        // Oct 10,2018
        let dateComponents1 = DateComponents(calendar: Calendar.current, year: 2018, month: 10, day: 10)
        let specificPastDate1 = Calendar.current.date(from: dateComponents1)!
        XCTAssertTrue(specificPastDate1.relativelyFormattedUpdateString.contains("Updated on Oct 10, 2018"))

        // Feb 2, 2016
        let dateComponents2 = DateComponents(calendar: Calendar.current, year: 2016, month: 2, day: 2)
        let specificPastDate2 = Calendar.current.date(from: dateComponents2)!
        XCTAssertTrue(specificPastDate2.relativelyFormattedUpdateString.contains("Updated on Feb 2, 2016"))
    }

    func testUpdateStringWorksForFutureIntervals() {

        // 1 second in future
        let futureDate = Calendar.current.date(byAdding: .second, value: 1, to: Date())!
        XCTAssertEqual(futureDate.relativelyFormattedUpdateString, "Updated moments ago")

        // 1 year in future
        let futureDate2 = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        XCTAssertEqual(futureDate2.relativelyFormattedUpdateString, "Updated moments ago")
    }
}
