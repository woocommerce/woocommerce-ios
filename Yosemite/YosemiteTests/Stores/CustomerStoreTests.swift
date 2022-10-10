import XCTest
@testable import Networking
@testable import Yosemite

class CustomerStoreTests: XCTestCase {

    private var dispatcher: Dispatcher!
    private var storageManager: MockStorageManager!
    private var network: MockNetwork!
    private var customerRemote: CustomerRemote!
    private var searchRemote: WCAnalyticsCustomerRemote!
    private var store: CustomerStore!
    private let dummySiteID: Int64 = 12345
    private let dummyCustomerID: Int64 = 1
    private let dummyKeyword: String = "John"

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        customerRemote = CustomerRemote(network: network)
        searchRemote = WCAnalyticsCustomerRemote(network: network)
        store = CustomerStore(
            dispatcher: dispatcher,
            storageManager: storageManager,
            network: network,
            customerRemote: customerRemote,
            searchRemote: searchRemote
        )
    }

    func test_retrieveCustomer_returns_Customer_upon_success() {
        // Given
        network.simulateResponse(requestUrlSuffix: "", filename: "customer")

        // When
        let result: Result<Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: self.dummySiteID, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_retrieveCustomer_returns_Error_upon_failure() {
        // Given
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "", error: expectedError)

        // When
        let result: Result<Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: self.dummySiteID, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_mapSearchResultsToCustomerObject_returns_Customer_upon_success() throws {
        // Given
        //network.simulateResponse(requestUrlSuffix: "", filename: "wc-analytics-customers")
        // Mock instead?
        let searchResults = [
            Networking.WCAnalyticsCustomer(userID: 1, name: "John"),
            Networking.WCAnalyticsCustomer(userID: 2, name: "Paul"),
            Networking.WCAnalyticsCustomer(userID: 3, name: "John.Merch")
        ]

        // When
        let result: Result<Customer, Error> = waitFor { promise in
            let action = CustomerAction.mapSearchResultsToCustomerObject(
                siteID: self.dummySiteID,
                searchResults: searchResults) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(searchResults[0].name, try result.get().firstName)
    }

    func test_searchCustomers_returns_Error_upon_failure() {
        // Given
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "", error: expectedError)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = CustomerAction.searchCustomers(
                siteID: self.dummySiteID,
                keyword: self.dummyKeyword) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        //Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }
}
