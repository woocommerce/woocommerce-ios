import XCTest
@testable import Networking

final class CouponReportListMapperTests: XCTestCase {

    /// Verifies that the whole list is parsed.
    ///
    func test_mapper_parses_all_reports_in_response() throws {
        let reports = try mapLoadAllCouponReportsResponse()
        XCTAssertEqual(reports.count, 1)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_mapper_parses_all_fields_in_result() throws {
        let reports = try mapLoadAllCouponReportsResponse()
        let report = reports[0]

        let expectedReport = CouponReport(couponId: 571, amount: 12, ordersCount: 1)

        XCTAssertEqual(report, expectedReport)
    }
}

// MARK: - Test Helpers
///
private extension CouponReportListMapperTests {

    /// Returns the CouponReportListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapReports(from filename: String) throws -> [CouponReport] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try CouponReportListMapper().map(response: response)
    }

    /// Returns the CouponsReport list from `coupon-reports.json`
    ///
    func mapLoadAllCouponReportsResponse() throws -> [CouponReport] {
        return try mapReports(from: "coupon-reports")
    }
}
