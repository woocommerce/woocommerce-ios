
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

    func test_it_returns_months_if_the_dates_are_more_than_a_month_apart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-04-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .months)
    }

    func test_it_returns_weeks_if_the_dates_are_more_than_a_week_apart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-04-07T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .weeks)
    }

    func test_it_returns_weeks_if_the_dates_are_exactly_seven_days_apart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-15T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .weeks)
    }

    func test_it_returns_days_if_the_dates_are_between_two_and_seven_days_apart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-10T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .days)
    }

    func test_it_returns_days_if_the_dates_are_exactly_six_days_apart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-14T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .days)
    }

    func test_it_returns_yesterday_if_the_dates_are_exactly_one_day_apart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-09T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .yesterday)
    }

    func test_it_returns_yesterday_if_the_dates_are_exactly_one_and_a_half_day_apart() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-09T00:12:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .yesterday)
    }

    func test_it_returns_today_if_the_dates_are_exactly_the_same() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .today)
    }

    func test_it_returns_today_if_the_dates_have_the_same_day_but_different_time() {
        let dateFrom = dateFormatter.date(from: "2020-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T23:59:59Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .today)
    }

    func test_it_returns_upcoming_if_the_dateFrom_is_a_day_after_dateTo() {
        let dateFrom = dateFormatter.date(from: "2020-03-09T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .upcoming)
    }

    func test_it_returns_upcoming_if_the_dateFrom_is_days_after_dateTo() {
        let dateFrom = dateFormatter.date(from: "2020-03-19T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .upcoming)
    }

    func test_it_returns_upcoming_if_the_dateFrom_is_exactly_a_month_after_dateTo() {
        let dateFrom = dateFormatter.date(from: "2020-04-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .upcoming)
    }

    func test_it_returns_upcoming_if_the_dateFrom_is_exactly_a_week_after_dateTo() {
        let dateFrom = dateFormatter.date(from: "2020-03-15T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .upcoming)
    }

    func test_it_returns_upcoming_if_the_dateFrom_is_exactly_a_year_after_dateTo() {
        let dateFrom = dateFormatter.date(from: "2021-03-08T00:00:00Z")!
        let dateTo = dateFormatter.date(from: "2020-03-08T00:00:00Z")!

        let age = Age.from(startDate: dateFrom, toDate: dateTo, using: calendar)

        XCTAssertEqual(age, .upcoming)
    }
}
