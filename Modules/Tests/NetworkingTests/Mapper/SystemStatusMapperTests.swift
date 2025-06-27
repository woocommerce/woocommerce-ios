import XCTest
@testable import Networking
@testable import NetworkingCore

/// SystemStatusMapper Unit Tests
///
final class SystemStatusMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 999999

    func test_system_status_fields_are_properly_parsed() throws {
        // When
        let status = try mapLoadSystemStatusResponse()

        // Then
        XCTAssertEqual(status.environment?.storeID, "sample-store-uuid")
        XCTAssertEqual(status.activePlugins.count, 4)
        XCTAssertEqual(status.activePlugins[0].siteID, dummySiteID)
        XCTAssertEqual(status.inactivePlugins.count, 2)
        XCTAssertEqual(status.inactivePlugins[1].siteID, dummySiteID)
    }

    func test_system_status_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        // When
        let status = try mapLoadSystemStatusResponseWithoutDataEnvelope()

        // Then
        XCTAssertEqual(status.activePlugins.count, 4)
        XCTAssertEqual(status.activePlugins[0].siteID, dummySiteID)
        XCTAssertEqual(status.inactivePlugins.count, 2)
        XCTAssertEqual(status.inactivePlugins[1].siteID, dummySiteID)
    }

    func test_system_status_fields_are_properly_parsed_when_response_has_inconsistent_data_type_for_page_id() throws {
        // When
        let status = try mapLoadSystemStatusResponseWithInconsistentPageIdDataType()

        // Then
        XCTAssertEqual(status.environment?.storeID, "sample-store-uuid")
        XCTAssertEqual(status.activePlugins.count, 4)
        XCTAssertEqual(status.activePlugins[0].siteID, dummySiteID)
        XCTAssertEqual(status.inactivePlugins.count, 2)
        XCTAssertEqual(status.inactivePlugins[1].siteID, dummySiteID)
    }

    func test_system_status_fields_are_properly_parsed_when_response_has_inconsistent_data_type_for_unused_environment_properties() throws {
        // When
        let status = try mapLoadSystemStatusResponseWithInconsistentEnvironmentMaxUploadSizeType()

        // Then
        XCTAssertEqual(status.environment?.storeID, "sample-store-uuid")
        XCTAssertEqual(status.activePlugins.count, 4)
        XCTAssertEqual(status.activePlugins[0].siteID, dummySiteID)
        XCTAssertEqual(status.inactivePlugins.count, 2)
        XCTAssertEqual(status.inactivePlugins[1].siteID, dummySiteID)
    }
}

private extension SystemStatusMapperTests {

    /// Returns the SystemStatusMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapReport(from filename: String) throws -> SystemStatus {
        guard let response = Loader.contentsOf(filename) else {
            throw NetworkError.notFound()
        }

        return try SystemStatusMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the SystemStatus output upon receiving `systemStatus.json`
    ///
    func mapLoadSystemStatusResponse() throws -> SystemStatus {
        return try mapReport(from: "systemStatus")
    }

    /// Returns the SystemStatus output upon receiving `systemStatus-without-data.json`
    ///
    func mapLoadSystemStatusResponseWithoutDataEnvelope() throws -> SystemStatus {
        return try mapReport(from: "systemStatus-without-data")
    }

    /// Returns the SystemStatus output upon receiving `systemStatus-inconsistent-page-id-data-type.json`
    ///
    func mapLoadSystemStatusResponseWithInconsistentPageIdDataType() throws -> SystemStatus {
        return try mapReport(from: "systemStatus-inconsistent-page-id-data-type")
    }

    /// Returns the SystemStatus output upon receiving `systemStatus-inconsistent-environment-max-upload-size-data-type.json`
    ///
    func mapLoadSystemStatusResponseWithInconsistentEnvironmentMaxUploadSizeType() throws -> SystemStatus {
        return try mapReport(from: "systemStatus-inconsistent-environment-max-upload-size-data-type")
    }
}
