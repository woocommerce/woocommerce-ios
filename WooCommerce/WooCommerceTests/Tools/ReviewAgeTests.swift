import XCTest
@testable import WooCommerce

final class ReviewAgeTests: XCTestCase {
    func testDescriptionReturnsExpectationFor24Hours() {
        let age = ReviewAge(rawValue: "0")

        XCTAssertEqual(age?.description, Expectations.today)
    }

    func testDescriptionReturnsExpectationSevenDays() {
        let age = ReviewAge(rawValue: "1")

        XCTAssertEqual(age?.description, Expectations.last7days)
    }

    func testDescriptionReturnsExpectationForOlder() {
        let age = ReviewAge(rawValue: "2")

        XCTAssertEqual(age?.description, Expectations.olderThan7Days)
    }

    /// We are going to assume that days are 84400 miliseconds
    /// which is wrong and inaccurate, but after all, this is software engineering,
    /// not real life
    func testAgeCalculationsReturnLast24HoursAgeFor12Hours() {
        let initialDate = Date()
        // Let's move the clock 12 hours ahead
        let finalDate = Date(timeInterval: 43200, since: initialDate)

        let age = ReviewAge.from(startDate: initialDate, toDate: finalDate)

        XCTAssertEqual(age, .last24Hours)
    }

    func testAgeCalculationsReturnLast24HoursAgeFor23Hours() {
        let initialDate = Date()
        // Let's move the clock 23:59:59 hours ahead
        let finalDate = Date(timeInterval: 84399, since: initialDate)

        let age = ReviewAge.from(startDate: initialDate, toDate: finalDate)

        XCTAssertEqual(age, .last24Hours)
    }

    func testAgeCalculationsReturnLast24HoursAgeFor24HoursAnd1Second() {
        let initialDate = Date()
        // Let's move the clock 24:00:01 hours ahead
        let finalDate = Date(timeInterval: 84461, since: initialDate)

        let age = ReviewAge.from(startDate: initialDate, toDate: finalDate)

        XCTAssertEqual(age, .last24Hours)
    }

    func testAgeCalculationsReturnLast7DaysAgeForThreeDays() {
        let initialDate = Date()
        // Let's move the clock three days ahead
        let finalDate = Date(timeInterval: 259200, since: initialDate)

        let age = ReviewAge.from(startDate: initialDate, toDate: finalDate)

        XCTAssertEqual(age, .last7Days)
    }

    func testAgeCalculationsReturnLast7DaysAgeForAlmostSevenFullDays() {
        let initialDate = Date()
        // Let's move the clock almost seven full days ahead
        let finalDate = Date(timeInterval: 604760, since: initialDate)

        let age = ReviewAge.from(startDate: initialDate, toDate: finalDate)

        XCTAssertEqual(age, .last7Days)
    }

    func testAgeCalculationsReturnLastOlderForMoreThanSevenFullDays() {
        let initialDate = Date()
        // Let's move the clock a tad longer than seven full days ahead
        let finalDate = Date(timeInterval: 691300, since: initialDate)

        let age = ReviewAge.from(startDate: initialDate, toDate: finalDate)

        XCTAssertEqual(age, .theRest)
    }
}


private extension ReviewAgeTests {
    enum Expectations {
        static let today = NSLocalizedString("Last 24 hours", comment: "Last 24 hours section header")
        static let last7days = NSLocalizedString("Last 7 days", comment: "Last 7 days section header")
        static let olderThan7Days = NSLocalizedString("Older than 7 days", comment: "+7 Days Section Header")
    }
}
