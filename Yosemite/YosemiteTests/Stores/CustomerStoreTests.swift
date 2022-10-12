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
    private let dummyCustomerID: Int64 = 25
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

    func test_retrieveCustomer_returns_customer_upon_success() throws {
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
        let customer = try result.get()
        XCTAssertEqual(customer.customerID, 25)
        XCTAssertEqual(customer.firstName, "John")
        XCTAssertEqual(customer.lastName, "Doe")
        XCTAssertEqual(customer.email, "john.doe@example.com")
        XCTAssertEqual(customer.billing?.firstName, "John" )
        XCTAssertEqual(customer.billing?.lastName, "Doe" )
        XCTAssertEqual(customer.billing?.address1, "969 Market" )
        XCTAssertEqual(customer.billing?.address2, "" )
        XCTAssertEqual(customer.billing?.city, "San Francisco" )
        XCTAssertEqual(customer.billing?.state, "CA" )
        XCTAssertEqual(customer.billing?.postcode, "94103" )
        XCTAssertEqual(customer.billing?.country, "US" )
        XCTAssertEqual(customer.billing?.email, "john.doe@example.com" )
        XCTAssertEqual(customer.billing?.phone, "(555) 555-5555" )
        XCTAssertEqual(customer.shipping?.firstName, "John" )
        XCTAssertEqual(customer.shipping?.lastName, "Doe" )
        XCTAssertEqual(customer.shipping?.company, "" )
        XCTAssertEqual(customer.shipping?.address1, "969 Market" )
        XCTAssertEqual(customer.shipping?.address2, "" )
        XCTAssertEqual(customer.shipping?.city, "San Francisco" )
        XCTAssertEqual(customer.shipping?.state, "CA" )
        XCTAssertEqual(customer.shipping?.postcode, "94103" )
        XCTAssertEqual(customer.shipping?.country, "US" )
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

    func test_searchCustomers_when_three_results_found_then_returns_an_array_with_three_customer_entities() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")
        network.simulateResponse(requestUrlSuffix: "customers/1", filename: "customer")
        network.simulateResponse(requestUrlSuffix: "customers/2", filename: "customer")
        network.simulateResponse(requestUrlSuffix: "customers/3", filename: "customer")

        // When
        let response: Result<[Customer], Error> = waitFor { promise in
            let action = CustomerAction.searchCustomers(siteID: self.dummySiteID, keyword: self.dummyKeyword) { result in
                promise(result)
            }
            self.dispatcher.dispatch(action)
        }

        // Then
        let customers = try response.get()
        XCTAssertEqual(customers.count, 3)
    }

    func test_searchCustomers_returns_Error_upon_failure() {
        // Given
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "", error: expectedError)

        // When
        let result: Result<[Customer], Error> = waitFor { promise in
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
