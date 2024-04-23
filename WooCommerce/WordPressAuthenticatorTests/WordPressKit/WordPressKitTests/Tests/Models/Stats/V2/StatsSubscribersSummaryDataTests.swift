import XCTest
@testable import WordPressKit

final class StatsSubscribersSummaryDataTests: XCTestCase {
    func testEmailsSummaryDecoding() throws {
        let json = getJSON("stats-subscribers")

        let summary = StatsSubscribersSummaryData(jsonDictionary: json)
        XCTAssertNotNil(summary, "StatsSubscribersSummaryData not decoded as expected")
        let history = summary!.history
        let firstDay = history[0]

        XCTAssertEqual(firstDay.date, ISO8601DateFormatter().date(from: "2024-04-22"))
        XCTAssertEqual(firstDay.count, 77)
    }
}

private extension StatsSubscribersSummaryDataTests {
    func getJSON(_ fileName: String) -> [String: AnyObject] {
        let path = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
    }
}
