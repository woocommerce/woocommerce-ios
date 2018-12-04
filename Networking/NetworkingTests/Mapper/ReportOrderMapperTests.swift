import XCTest
@testable import Networking


/// ReportOrderMapper Unit Tests
///
class ReportOrderMapperTests: XCTestCase {
    /// Verifies that the broken response causes the mapper to return an unknown status
    ///
    func testBrokenResponseReturnsUnknownStatus() {
        let reportTotals = try? mapLoadBrokenResponse()
        XCTAssertNil(reportTotals)
    }
    /// Verifies that a valid report totals response is properly parsed (YAY!).
    ///
    func testSampleResponseLoaded() {
        let reportTotals = try? mapSuccessfulResponse()
        XCTAssertNotNil(reportTotals)
        XCTAssertEqual(reportTotals?.count, 8)
        XCTAssertEqual(reportTotals?[.pending], 123)
        XCTAssertEqual(reportTotals?[.processing], 4)
        XCTAssertEqual(reportTotals?[.onHold], 5)
        XCTAssertEqual(reportTotals?[.completed], 6)
        XCTAssertEqual(reportTotals?[.cancelled], 7)
        XCTAssertEqual(reportTotals?[.refunded], 8)
        XCTAssertEqual(reportTotals?[.failed], 9)
        XCTAssertEqual(reportTotals?[OrderStatus(rawValue: "cia-investigation")], 10)
    }
}
/// Private Methods.
///
private extension ReportOrderMapperTests {
    /// Returns the ReportOrderMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrderStatusResult(from filename: String) throws -> [OrderStatus: Int] {
        let response = Loader.contentsOf(filename)!
        let mapper = ReportOrderTotalsMapper()
        return try mapper.map(response: response)
    }
    /// Returns the ReportOrderMapper output upon receiving data from the endpoint
    ///
    func mapSuccessfulResponse() throws -> [OrderStatus: Int] {
        return try mapOrderStatusResult(from: "report-orders")
    }
    /// Returns the ReportOrderMapper output upon receiving a broken response.
    ///
    func mapLoadBrokenResponse() throws -> [OrderStatus: Int] {
        return try mapOrderStatusResult(from: "generic_error")
    }
}
