import XCTest
@testable import Networking

class CustomerRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    private var remote: CustomerRemote!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    /// Dummy Customer ID
    private let sampleCustomerID: Int64 = 25

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        remote = CustomerRemote(network: network)
    }

    override func tearDown() {
        network = nil
        remote = nil
        super.tearDown()
    }

    /// Verifies that retrieveCustomer simulated response is successful for a given customerID
    ///
    func test_CustomerRemote_when_retrieveCustomer_then_returns_result_isSuccess() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers/\(sampleCustomerID)", filename: "customer")

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomer(for: self.sampleSiteID, with: self.sampleCustomerID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
    }

    /// Verifies that retrieveCustomer  properly parses the `wc/v3/customers/{customerID}` endpoint sample response.
    ///
    func test_retrieveCustomer_returns_parsed_customer_successfully() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers/\(sampleCustomerID)", filename: "customer")

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomer(for: self.sampleSiteID, with: self.sampleCustomerID) { result in
                promise(result)
            }
        }
        let customer = try XCTUnwrap(result.get())

        // Then
        XCTAssertNotNil(customer)
    }
}
