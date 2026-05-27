import XCTest
@testable import Networking
@testable import NetworkingCore

final class POSStaffRemoteTests: XCTestCase {
    private var network: MockNetwork!
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_fetchStaff_when_response_is_successful_then_returns_staff_array() async throws {
        // Given
        let remote = POSStaffRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "staff", filename: "pos-staff-list")

        // When
        let staff = try await remote.fetchStaff(siteID: sampleSiteID)

        // Then
        XCTAssertEqual(staff.count, 3)
        XCTAssertEqual(staff.map(\.userID), [1, 7, 42])
    }

    func test_fetchStaff_when_network_errors_then_throws() async {
        // Given
        let remote = POSStaffRemote(network: network)
        let sampleError = NSError(domain: "POSStaff", code: 1, userInfo: nil)
        network.simulateError(requestUrlSuffix: "staff", error: sampleError)

        // When / Then
        do {
            _ = try await remote.fetchStaff(siteID: sampleSiteID)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 1)
        }
    }
}
