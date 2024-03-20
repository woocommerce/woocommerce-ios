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
        let filter = "all"
        let pageNumber = 1
        let pageSize = 25
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            self.remote.searchCustomers(for: self.sampleSiteID,
                                        pageNumber: pageNumber,
                                        pageSize: pageSize,
                                        orderby: .name,
                                        order: .asc,
                                        keyword: self.sampleCustomerName,
                                        filter: filter,
                                        filterEmpty: .email) { result in
                promise(result)
            }
        }

        // Then
        let customers = try XCTUnwrap(result.get())
        let hasSearchParameter = network.queryParameters?.contains(where: { $0 == "search=\(sampleCustomerName)" }) ?? false
        let hasSearchByParameter = network.queryParameters?.contains(where: { $0 == "searchby=\(filter)" }) ?? false
        let hasPageNumberParameter = network.queryParameters?.contains(where: { $0 == "page=\(pageNumber)" }) ?? false
        let hasPageSizeParameter = network.queryParameters?.contains(where: { $0 == "per_page=\(pageSize)" }) ?? false
        let hasOrderByParameter = network.queryParameters?.contains(where: { $0 == "orderby=name" }) ?? false
        let hasOrderParameter = network.queryParameters?.contains(where: { $0 == "order=asc" }) ?? false
        let hasFilterEmptyParameter = network.queryParameters?.contains(where: { $0 == "filter_empty=email" }) ?? false

        XCTAssertTrue(hasSearchParameter)
        XCTAssertTrue(hasSearchByParameter)
        XCTAssertTrue(hasPageNumberParameter)
        XCTAssertTrue(hasPageSizeParameter)
        XCTAssertTrue(hasOrderByParameter)
        XCTAssertTrue(hasOrderParameter)
        XCTAssertTrue(hasFilterEmptyParameter)

        assertParsedResultsAreCorrect(with: customers)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_loadCustomers_then_returns_parsed_customers_successfully() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")
        let pageNumber = 2
        let pageSize = 25

        // When
        let result = waitFor { promise in
            self.remote.loadCustomers(for: self.sampleSiteID,
                                      pageNumber: 2,
                                      pageSize: pageSize,
                                      orderby: .name,
                                      order: .asc,
                                      filterEmpty: .email) { result in
                promise(result)
            }
        }

        // Then
        let customers = try XCTUnwrap(result.get())

        let hasPageNumberParameter = network.queryParameters?.contains(where: { $0 == "page=\(pageNumber)" }) ?? false
        let hasPageSizeParameter = network.queryParameters?.contains(where: { $0 == "per_page=\(pageSize)" }) ?? false
        let hasOrderByParameter = network.queryParameters?.contains(where: { $0 == "orderby=name" }) ?? false
        let hasOrderParameter = network.queryParameters?.contains(where: { $0 == "order=asc" }) ?? false
        let hasFilterEmptyParameter = network.queryParameters?.contains(where: { $0 == "filter_empty=email" }) ?? false

        XCTAssertTrue(hasPageNumberParameter)
        XCTAssertTrue(hasPageSizeParameter)
        XCTAssertTrue(hasOrderByParameter)
        XCTAssertTrue(hasOrderParameter)
        XCTAssertTrue(hasFilterEmptyParameter)

        assertParsedResultsAreCorrect(with: customers)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomersByName_fails_then_returns_result_isFailure() {
        // Given
        network.simulateError(requestUrlSuffix: "", error: NetworkError.notFound())

        // When
        let result = waitFor { promise in
            self.remote.searchCustomers(for: self.sampleSiteID,
                                        pageNumber: 1,
                                        pageSize: 25,
                                        orderby: .name,
                                        order: .asc,
                                        keyword: self.sampleCustomerName,
                                        filter: "all",
                                        filterEmpty: nil) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }

    func test_WCAnalyticsCustomerRemote_when_calls_retrieveCustomersByName_returns_early_and_fails_if_search_term_is_empty() {

        // Given
        network.simulateError(requestUrlSuffix: "customers?search=", error: NetworkError.notFound())

        // When
        let result = waitFor { promise in
            self.remote.searchCustomers(for: self.sampleSiteID,
                                        pageNumber: 1,
                                        pageSize: 25,
                                        orderby: .name,
                                        order: .asc,
                                        keyword: self.sampleCustomerName,
                                        filter: "all",
                                        filterEmpty: nil) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isFailure)
    }
}

private extension WCAnalyticsCustomerRemoteTests {
    func assertParsedResultsAreCorrect(with customers: [WCAnalyticsCustomer]) {
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
}
