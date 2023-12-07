import XCTest
@testable import Networking

final class CouponReportListMapperTests: XCTestCase {

    /// Verifies that the whole list is parsed.
    ///
    func test_mapper_parses_all_reports_in_response() async throws {
        // Given
        let reports = try await mapLoadAllCouponReportsResponseWithDataEnvelope()

        // Then
        XCTAssertEqual(reports.count, 1)
    }

    /// Verifies that the whole list is parsed.
    ///
    func test_mapper_parses_all_reports_in_response_without_data_envelop() async throws {
        // Given
        let reports = try await mapLoadAllCouponReportsResponseWithoutDataEnvelope()

        // Then
        XCTAssertEqual(reports.count, 1)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_mapper_parses_all_fields_in_result() async throws {
        // Given
        let reports = try await mapLoadAllCouponReportsResponseWithDataEnvelope()
        let report = reports[0]
        let expectedReport = CouponReport(couponID: 571, amount: 12, ordersCount: 1)

        // Then
        XCTAssertEqual(report, expectedReport)
    }
}

// MARK: - Test Helpers
///
private extension CouponReportListMapperTests {

    /// Returns the CouponReportListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapReports(from filename: String) async throws -> [CouponReport] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try await CouponReportListMapper().map(response: response)
    }

    /// Returns the CouponsReport list from `coupon-reports.json`
    ///
    func mapLoadAllCouponReportsResponseWithDataEnvelope() async throws -> [CouponReport] {
        return try await mapReports(from: "coupon-reports")
    }

    /// Returns the CouponsReport list from `coupon-reports-without-data.json`
    ///
    func mapLoadAllCouponReportsResponseWithoutDataEnvelope() async throws -> [CouponReport] {
        return try await mapReports(from: "coupon-reports-without-data")
    }
}
