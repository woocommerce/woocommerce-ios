import XCTest
@testable import Networking


/// ReportOrderMapper Unit Tests
///
class ReportOrderMapperTests: XCTestCase {

    /// Sample SiteID
    ///
    let siteID: Int64 = 1234

    /// Verifies that the broken response causes the mapper to return an unknown status
    ///
    func testBrokenResponseReturnsUnknownStatus() {
        let reportTotals = try? mapLoadBrokenResponse()
        XCTAssertNil(reportTotals)
    }

    /// Verifies that a valid report totals response is properly parsed (YAY!).
    ///
    func testSampleResponseLoaded() {
        guard let results = try? mapSuccessfulResponse() else {
            XCTFail("Sample order report totals didn't load.")
            return
        }

        var reportTotals = [OrderStatusEnum: Int]()
        results.forEach({ (orderStatus) in
            let status = OrderStatusEnum(rawValue: orderStatus.slug)
            reportTotals[status] = orderStatus.total
        })
        let orderStatuses = results

        XCTAssertNotNil(reportTotals)
        XCTAssertEqual(reportTotals.count, 9)
        XCTAssertEqual(reportTotals[.pending], 123)
        XCTAssertEqual(reportTotals[.processing], 4)
        XCTAssertEqual(reportTotals[.onHold], 5)
        XCTAssertEqual(reportTotals[.completed], 6)
        XCTAssertEqual(reportTotals[.cancelled], 7)
        XCTAssertEqual(reportTotals[.refunded], 8)
        XCTAssertEqual(reportTotals[.failed], 9)
        XCTAssertEqual(reportTotals[OrderStatusEnum(rawValue: "cia-investigation")], 10)
        XCTAssertEqual(reportTotals[OrderStatusEnum(rawValue: "pre-ordered")], 1)

        XCTAssertNotNil(orderStatuses)
        XCTAssertEqual(orderStatuses.count, 9)

        let ciaOrderStatus = OrderStatus(name: "CIA Investigation", siteID: 1234, slug: "cia-investigation", total: 10)
        let preorderedOrderStatus = OrderStatus(name: "Pre ordered", siteID: 1234, slug: "pre-ordered", total: 1)

        XCTAssertEqual(orderStatuses[0].slug, "pending")
        XCTAssertEqual(orderStatuses[0].name, "Pending payment")
        XCTAssertEqual(orderStatuses[0].status, .pending)

        XCTAssertEqual(orderStatuses[1].slug, "processing")
        XCTAssertEqual(orderStatuses[1].name, "Processing")
        XCTAssertEqual(orderStatuses[1].status, .processing)

        XCTAssertEqual(orderStatuses[2].slug, "on-hold")
        XCTAssertEqual(orderStatuses[2].name, "On hold")
        XCTAssertEqual(orderStatuses[2].status, .onHold)

        XCTAssertEqual(orderStatuses[3].slug, "completed")
        XCTAssertEqual(orderStatuses[3].name, "Completed")
        XCTAssertEqual(orderStatuses[3].status, .completed)

        XCTAssertEqual(orderStatuses[4].slug, "cancelled")
        XCTAssertEqual(orderStatuses[4].name, "Cancelled")
        XCTAssertEqual(orderStatuses[4].status, .cancelled)

        XCTAssertEqual(orderStatuses[5].slug, "refunded")
        XCTAssertEqual(orderStatuses[5].name, "Refunded")
        XCTAssertEqual(orderStatuses[5].status, .refunded)

        XCTAssertEqual(orderStatuses[6].slug, "failed")
        XCTAssertEqual(orderStatuses[6].name, "Failed")
        XCTAssertEqual(orderStatuses[6].status, .failed)

        XCTAssertEqual(orderStatuses[7].slug, "cia-investigation")
        XCTAssertEqual(orderStatuses[7].name, "CIA Investigation")
        XCTAssertEqual(orderStatuses[7].status, ciaOrderStatus.status)

        XCTAssertEqual(orderStatuses[8].slug, "pre-ordered")
        XCTAssertEqual(orderStatuses[8].name, "Pre ordered")
        XCTAssertEqual(orderStatuses[8].status, preorderedOrderStatus.status)
    }
}


/// Private Methods.
///
private extension ReportOrderMapperTests {

    /// Returns the ReportOrderMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrderStatusResult(from filename: String) throws -> [OrderStatus] {
        let response = Loader.contentsOf(filename)!
        let mapper = ReportOrderTotalsMapper(siteID: 1234)
        return try mapper.map(response: response)
    }

    /// Returns the ReportOrderMapper output upon receiving data from the endpoint
    ///
    func mapSuccessfulResponse() throws -> [OrderStatus] {
        return try mapOrderStatusResult(from: "report-orders")
    }

    /// Returns the ReportOrderMapper output upon receiving a broken response.
    ///
    func mapLoadBrokenResponse() throws -> [OrderStatus] {
        return try mapOrderStatusResult(from: "generic_error")
    }
}
