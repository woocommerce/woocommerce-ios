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

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomersByName_then_returns_parsed_customers_successfully() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers?search=\(sampleCustomerName)", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomersByName(for: self.sampleSiteID, with: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        let customers = try XCTUnwrap(result.get())
        XCTAssertEqual(customers.count, 2)
        XCTAssertEqual(customers[0].userID, 1)
        XCTAssertEqual(customers[1].userID, 3)
        XCTAssertEqual(customers[0].name, "John")
        XCTAssertEqual(customers[1].name, "John Doe")
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomersByName_fails_then_returns_result_isFailure() {
        // Given
        network.simulateError(requestUrlSuffix: "", error: NetworkError.notFound)

        // When
        let result = waitFor { promise in
            self.remote.retrieveCustomersByName(for: self.sampleSiteID, with: self.sampleCustomerName) { result in
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
            self.remote.retrieveCustomersByName(for: self.sampleSiteID, with: self.sampleCustomerName) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }
}
