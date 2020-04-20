
import XCTest
import UIKit
import Foundation
@testable import WooCommerce

/// Tests for the `Age.from` method.
///
final class AgeTests: XCTestCase {

    private var dateFormatter: DateFormatter!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()

        dateFormatter = DateFormatter.Defaults.iso8601
        calendar = Calendar(identifier: .gregorian, timeZone: dateFormatter.timeZone)
    }

    override func tearDown() {
        calendar = nil
        dateFormatter = nil
        super.tearDown()
    }

    func testItReturnsMonthsIfTheDatesAreMoreThanAMonthApart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-04-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .months)
    }

    func testItReturnsWeeksIfTheDatesAreMoreThanAWeekApart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-04-07T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .weeks)
    }

    func testItReturnsWeeksIfTheDatesAreExactlySevenDaysApart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-15T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .weeks)
    }

    func testItReturnsDaysIfTheDatesAreBetweenTwoAndSevenDaysApart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-10T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .days)
    }

    func testItReturnsDaysIfTheDatesAreExactlySixDaysApart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-14T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .days)
    }

    func testItReturnsYesterdayIfTheDatesAreExactlyOneDayApart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-09T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .yesterday)
    }

    func testItReturnsYesterdayIfTheDatesAreExactlyOneAndAHalfDayApart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-09T00:12:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .yesterday)
    }

    func testItReturnsTodayIfTheDatesAreExactlyTheSame() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .today)
    }

    func testItReturnsTodayIfTheDatesHaveTheSameDayButDifferentTime() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T23:59:59Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .today)
    }

    func testItReturnsUpcomingIfTheDateFromIsADayAfterDateTo() {
        let dateFrom = dateFormatter.date(from: "2020-03-09T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .upcoming)
    }

    func testItReturnsUpcomingIfTheDateFromIsDaysAfterDateTo() {
        let dateFrom = dateFormatter.date(from: "2020-03-19T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .upcoming)
    }
}
