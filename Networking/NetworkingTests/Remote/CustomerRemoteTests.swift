import XCTest
@testable import Networking

class CustomerRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    /// Dummy Customer ID
    private let sampleCustomerID: Int64 = 25

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    /// Verifies that retrieveCustomer  properly parses the `wc/v3/customers/{customerID}` endpoint sample response.
    ///
    func test_retrieveCustomer_returns_parsed_customer_successfully() throws {
        // Given
        let remote = CustomerRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "customers/\(sampleCustomerID)", filename: "customer")

        // When
        let result = waitFor { promise in
            remote.retrieveCustomer(for: self.sampleSiteID, with: self.sampleCustomerID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let customer = try XCTUnwrap(result.get())
        XCTAssertNotNil(customer)
    }
}
