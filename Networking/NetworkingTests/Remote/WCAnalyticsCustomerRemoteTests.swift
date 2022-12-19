import XCTest
import TestKit
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

    func test_WCAnalyticsCustomerRemote_when_calls_searchCustomers_then_returns_parsed_customers_successfully() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            self.remote.searchCustomers(for: self.sampleSiteID, name: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        let customers = try XCTUnwrap(result.get())
        let hasSearchParameter = network.queryParameters?.contains(where: { $0 == "search=John" }) ?? false
        XCTAssertTrue(hasSearchParameter)
        assertEqual(4, customers.count)
        assertEqual(0, customers[0].userID)
        assertEqual(1, customers[1].userID)
        assertEqual(2, customers[2].userID)
        assertEqual(3, customers[3].userID)
        assertEqual("Matt The Unregistered", customers[0].name)
        assertEqual("John", customers[1].name)
        assertEqual("Paul", customers[2].name)
        assertEqual("John Doe", customers[3].name)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomersByName_fails_then_returns_result_isFailure() {
        // Given
        network.simulateError(requestUrlSuffix: "", error: NetworkError.notFound)

        // When
        let result = waitFor { promise in
            self.remote.searchCustomers(for: self.sampleSiteID, name: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomersByName_returns_early_and_fails_if_search_term_is_empty() {

        // Given
        network.simulateError(requestUrlSuffix: "customers?search=", error: NetworkError.notFound)

        // When
        let result = waitFor { promise in
            self.remote.searchCustomers(for: self.sampleSiteID, name: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }
}
