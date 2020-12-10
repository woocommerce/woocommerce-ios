import XCTest
import TestKit
@testable import Networking

/// CustomerRemote Unit Tests
///
final class CustomerRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    let network = MockNetwork()

    /// Dummy Site ID
    let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_getAllCustomers_returns_parsed_customers() throws {
        // Given
        let remote = CustomerRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customers-all")

        // When
        let result = try waitFor { promise in
            remote.getAllCustomers(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.count, 2)

        let expectedId: Int64 = 25
        guard let expectedCustomer = response.first(where: { $0.userID == expectedId }) else {
            XCTFail("Customer with id \(expectedId) should exist")
            return
        }
        XCTAssertEqual(expectedCustomer.siteID, self.sampleSiteID)
        XCTAssertEqual(expectedCustomer.username, "john.doe")
    }
}
