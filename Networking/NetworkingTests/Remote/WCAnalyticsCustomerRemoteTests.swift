import XCTest
@testable import Networking

class WCAnalyticsCustomerRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    private var remote: WCAnalyticsCustomerRemote!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        remote = WCAnalyticsCustomerRemote(network: network)
    }

    override func tearDown() {
        network = nil
        remote = nil
        super.tearDown()
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomers_then_returns_result_isSuccess() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomers(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomers_fails_then_returns_result_isFailure() {
        // Given
        network.simulateError(requestUrlSuffix: "", error: NetworkError.notFound)

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomers(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomers_then_returns_all_parsed_customers_successfully() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomers(for: self.sampleSiteID) { result in
                promise(result)
            }
        }
        let customers = try XCTUnwrap(result.get())

        // Then
        XCTAssertNotNil(customers)
        XCTAssertEqual(customers[0].userID, 1)
        XCTAssertEqual(customers[1].userID, 2)
        XCTAssertEqual(customers[0].name, "Order name #1")
        XCTAssertEqual(customers[1].name, "Order name #2")
    }
}
