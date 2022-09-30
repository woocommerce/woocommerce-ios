import XCTest
@testable import Networking

class WCAnalyticsCustomerRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    private var remote: WCAnalyticsCustomerRemote!

    /// Sample Site ID
    ///
    private let sampleSiteID: Int64 = 123

    /// Sample Customer name
    ///
    private let sampleCustomerName = "John"

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
        XCTAssertEqual(customers.count, 2)
        XCTAssertEqual(customers[0].userID, 1)
        XCTAssertEqual(customers[1].userID, 2)
        XCTAssertEqual(customers[0].name, "John")
        XCTAssertEqual(customers[1].name, "Paul")
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomerByName_then_returns_parsed_customer_successfully() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers?search=\(sampleCustomerName)", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomerByName(for: self.sampleSiteID, with: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        let customers = try XCTUnwrap(result.get())
        XCTAssertEqual(customers.count, 1)
        XCTAssertEqual(customers[0].userID, 1)
        XCTAssertEqual(customers[0].name, "John")
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

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomerByName_fails_then_returns_result_isFailure() {
        // Given
        network.simulateError(requestUrlSuffix: "", error: NetworkError.notFound)

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomerByName(for: self.sampleSiteID, with: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomerByName_returns_early_and_fails_if_search_term_is_empty() {

        // Given
        network.simulateError(requestUrlSuffix: "customers?search=", error: NetworkError.notFound)

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomerByName(for: self.sampleSiteID, with: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }
}
