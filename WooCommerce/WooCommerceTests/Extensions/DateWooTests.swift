import XCTest
import YosemiteTestHelpers
@testable import WooCommerce
@testable import Yosemite


/// Date+Woo: Unit Tests
///
final class DateWooTests: XCTestCase {

    private let originalStores: StoresManager = ServiceLocator.stores

    override func tearDown() {
        ServiceLocator.setStores(originalStores)
        ServiceLocator.stores.removeDefaultStore()
        super.tearDown()
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

    func testTheAddingMethodUsingDaysReturnsTheExpectedTargetWithTheSameTime() {
        // Given
        let formatter = DateFormatter.Defaults.iso8601
        let calendar = Calendar(identifier: .gregorian, timeZone: formatter.timeZone)

        let fromDate = formatter.date(from: "2020-03-08T14:53:11Z")!

        // When
        let actual = fromDate.adding(days: 5, using: calendar)

        // Then
        let expected = formatter.date(from: "2020-03-13T14:53:11Z")!
        XCTAssertEqual(actual, expected)
    }

    func testTheAddingMethodUsingDaysAndSecondsReturnsTheExpectedDateCalculation() {
        // Given
        let formatter = DateFormatter.Defaults.iso8601
        let calendar = Calendar(identifier: .gregorian, timeZone: formatter.timeZone)

        let fromDate = formatter.date(from: "2020-03-08T01:59:59Z")!

        // When
        let actual = fromDate.adding(days: 1, seconds: 1, using: calendar)

        // Then
        let expected = formatter.date(from: "2020-03-09T02:00:00Z")!
        XCTAssertEqual(actual, expected)
    }

    /// For example, if Date() is 2020-01-01 01:00:00, then nextMidnight() should return
    /// 2020-01-02 00:00:00.
    func testNextMidnightMethodReturnsTomorrowWithoutTime() {
        // Given
        let formatter = DateFormatter.Defaults.iso8601
        let calendar = Calendar(identifier: .gregorian, timeZone: formatter.timeZone)

        let fromDate = formatter.date(from: "2020-03-08T01:56:12Z")!

        // When
        let actual = fromDate.nextMidnight(using: calendar)

        // Then
        let expected = formatter.date(from: "2020-03-09T00:00:00Z")!
        XCTAssertEqual(actual, expected)
    }

    // MARK: - `toString(dateStyle:timeStyle:timeZone:locale:)`

    func test_toString_returns_date_string_in_given_time_zone() throws {
        // Given
        // GMT: Monday, December 25, 2023 3:23:31 AM
        let date = Date(timeIntervalSince1970: 1703474611)
        // For time zone GMT-12, the identifier used is "Etc/GMT+12" and not "Etc/GMT-12" which might seem more intuitive,
        // this is due to the way that these identifiers are standardized.
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Etc/GMT+12"))
        let locale = Locale(identifier: "en_US")

        // When
        let dateString = date.toString(dateStyle: .short, timeStyle: .full, timeZone: timeZone, locale: locale)

        // Then
        XCTAssertEqual(dateString, "12/24/23, 3:23:31 PM GMT-12:00")
    }

    // MARK: - `toStringInSiteTimeZone(dateStyle:timeStyle:locale:)`

    func test_toStringInSiteTimeZone_returns_date_string_in_site_time_zone() throws {
        // Given
        // GMT: Monday, December 25, 2023 3:23:31 AM
        let date = Date(timeIntervalSince1970: 1703474611)
        let site = Site.fake().copy(siteID: 1, gmtOffset: -12)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        ServiceLocator.setStores(stores)
        let locale = Locale(identifier: "en_US")

        // When
        let dateString = date.toStringInSiteTimeZone(dateStyle: .short, timeStyle: .full, locale: locale)

        // Then
        XCTAssertEqual(dateString, "12/24/23, 3:23:31 PM GMT-12:00")
    }
}
