import XCTest
import YosemiteTestHelpers
@testable import Networking
@testable import Yosemite
@testable import Storage

final class CustomerStoreTests: XCTestCase {

    private var dispatcher: Dispatcher!
    private var storageManager: MockStorageManager!
    private var viewStorage: StorageType!
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
        viewStorage = storageManager.viewStorage
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
        let result: Result<Networking.Customer, Error> = waitFor { promise in
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
        let expectedError = NetworkError.notFound()
        network.simulateError(requestUrlSuffix: "", error: expectedError)

        // When
        let result: Result<Networking.Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: self.dummySiteID, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_synchronizeLightCustomersData_retrieves_wc_analytics_customers_and_parses_them_to_customers() {
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            let action = CustomerAction.synchronizeLightCustomersData(siteID: self.dummySiteID,
                                                                      pageNumber: 1,
                                                                      pageSize: 2,
                                                                      orderby: .name,
                                                                      order: .asc) { result in
                promise(result)
            }
            self.dispatcher.dispatch(action)
        }

        let customers = viewStorage
            .loadAllCustomers(siteID: dummySiteID)
            .map { $0.toReadOnly() }
            .sorted(by: { $0.customerID < $1.customerID })

        guard case .success(let thereAreCustomers) = result else {
            XCTFail()

            return
        }

        XCTAssertTrue(thereAreCustomers)
        assertEqual(4, customers.count)
        assertEqual(0, customers[0].customerID)
        assertEqual(1, customers[1].customerID)
        assertEqual(2, customers[2].customerID)
        assertEqual(3, customers[3].customerID)
        // 3-word name.
        assertEqual("Matt", customers[0].firstName)
        assertEqual("The Unregistered", customers[0].lastName)
        // 1-word name.
        assertEqual("John", customers[1].firstName)
        XCTAssertTrue(customers[1].lastName?.isEmpty ?? true)
        // Empty name.
        XCTAssertTrue(customers[2].firstName?.isEmpty ?? true)
        XCTAssertTrue(customers[2].lastName?.isEmpty ?? true)
        // 2-word name.
        assertEqual("John", customers[3].firstName)
        assertEqual("Doe", customers[3].lastName)
    }

    func test_searchCustomers_returns_Error_upon_failure() {
        // Given
        let expectedError = NetworkError.notFound()
        network.simulateError(requestUrlSuffix: "", error: expectedError)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = CustomerAction.searchCustomers(
                siteID: self.dummySiteID,
                pageNumber: 1,
                pageSize: 25,
                orderby: .name,
                order: .asc,
                keyword: self.dummyKeyword,
                filter: .name) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        //Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_searchCustomers_upserts_the_returned_CustomerSearchResult() {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.CustomerSearchResult.self), 0)

        // When
        let response: Result<Bool, Error> = waitFor { promise in
            let action = CustomerAction.searchCustomers(siteID: self.dummySiteID,
                                                        pageNumber: 1,
                                                        pageSize: 25,
                                                        orderby: .name,
                                                        order: .asc,
                                                        keyword: self.dummyKeyword,
                                                        filter: .name) { result in
                promise(result)
            }
            self.dispatcher.dispatch(action)
        }

        // Then
        XCTAssertTrue(response.isSuccess)
        // Verify hasNextPage is false since we received 4 customers with pageSize 25
        XCTAssertEqual(try? response.get(), false)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 4)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.CustomerSearchResult.self), 1)

        let storedCustomerSearchResults = viewStorage.loadCustomerSearchResult(siteID: dummySiteID, keyword: dummyKeyword)

        XCTAssertNotNil(storedCustomerSearchResults)
        XCTAssertEqual(storedCustomerSearchResults?.siteID, dummySiteID)
        XCTAssertEqual(storedCustomerSearchResults?.keyword, dummyKeyword)
        XCTAssertEqual(storedCustomerSearchResults?.customers?.count, 4)
    }

    func test_searchCustomers_when_loading_a_second_page_then_appends_to_the_first_and_keeps_guests_separate() {
        // Given
        let pagedNetwork = MockNetwork(useResponseQueue: true)
        let pagedStore = CustomerStore(
            dispatcher: dispatcher,
            storageManager: storageManager,
            network: pagedNetwork,
            customerRemote: CustomerRemote(network: pagedNetwork),
            searchRemote: WCAnalyticsCustomerRemote(network: pagedNetwork)
        )
        pagedNetwork.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")
        pagedNetwork.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers-page-2")

        // When
        for pageNumber in 1...2 {
            () = waitFor { promise in
                let action = CustomerAction.searchCustomers(siteID: self.dummySiteID,
                                                            pageNumber: pageNumber,
                                                            pageSize: 4,
                                                            orderby: .name,
                                                            order: .asc,
                                                            keyword: self.dummyKeyword,
                                                            filter: .name) { _ in
                    promise(())
                }
                pagedStore.onAction(action)
            }
        }

        // Then
        // Only page 1 resets the stored customers, so the 2 from page 2 are added to the 4 from page 1.
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 6)

        // Guests share customerID 0, so each one is stored as its own row rather than overwriting the previous.
        let guests = viewStorage.allObjects(ofType: Storage.Customer.self,
                                            matching: NSPredicate(format: "siteID == %lld AND customerID == 0", dummySiteID),
                                            sortedBy: nil)
        XCTAssertEqual(guests.count, 2)
        XCTAssertEqual(Set(guests.compactMap { $0.firstName }), ["Matt", "Jane"])

        let storedCustomerSearchResults = viewStorage.loadCustomerSearchResult(siteID: dummySiteID, keyword: dummyKeyword)
        XCTAssertEqual(storedCustomerSearchResults?.customers?.count, 6)
    }

    func test_retrieveCustomer_upserts_the_returned_Customer() {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers/25", filename: "customer")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)

        // When
        let result: Result<Networking.Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: self.dummySiteID, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 1)

        let storedCustomer = viewStorage.loadCustomer(siteID: dummySiteID, customerID: dummyCustomerID)
        XCTAssertNotNil(storedCustomer)
        XCTAssertEqual(storedCustomer?.siteID, dummySiteID)
        XCTAssertEqual(storedCustomer?.customerID, dummyCustomerID)
        XCTAssertEqual(storedCustomer?.firstName, "John")
    }

    func test_searchCustomers_stores_unregistered_customers_from_the_results() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        // When
        () = waitFor { promise in
            let action = CustomerAction.searchCustomers(siteID: self.dummySiteID,
                                                        pageNumber: 1,
                                                        pageSize: 25,
                                                        orderby: .name,
                                                        order: .asc,
                                                        keyword: self.dummyKeyword,
                                                        filter: .name) { _ in
                promise(())
            }
            self.dispatcher.dispatch(action)
        }

        // Then
        let unregisteredCustomer = try XCTUnwrap(viewStorage.loadCustomer(siteID: dummySiteID, customerID: 0))
        XCTAssertEqual(unregisteredCustomer.firstName, "Matt")
        XCTAssertEqual(unregisteredCustomer.lastName, "The Unregistered")
    }

    func test_deleteAllCustomers() {
        let customer = Customer.fake().copy(siteID: dummySiteID)
        storageManager.insertSampleCustomer(readOnlyCustomer: customer)
        let customersBeforeDeleting = viewStorage.allObjects(ofType: Storage.Customer.self, matching: nil, sortedBy: nil)

        XCTAssertEqual(customersBeforeDeleting.count, 1)

        // When
        () = waitFor { promise in
            let action = CustomerAction.deleteAllCustomers(siteID: self.dummySiteID) {
                promise(())
            }

            self.dispatcher.dispatch(action)
        }

        let customersAfterDeleting = viewStorage.allObjects(ofType: Storage.Customer.self, matching: nil, sortedBy: nil)

        XCTAssertEqual(customersAfterDeleting.count, 0)
    }

    func test_synchronizeAllCustomers_upserts_WCAnalyticsCustomers_upon_success() {
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        // When
        let result = waitFor { promise in
            let action = CustomerAction.synchronizeAllCustomers(siteID: self.dummySiteID,
                                                                pageNumber: 1,
                                                                pageSize: 4) { result in
                promise(result)
            }
            self.dispatcher.dispatch(action)
        }

        let customers = viewStorage
            .loadAllWCAnalyticsCustomers(siteID: dummySiteID)
            .map { $0.toReadOnly() }
            .sorted(by: { $0.customerID < $1.customerID })

        guard case .success(let hasNextPage) = result else {
            XCTFail()

            return
        }

        XCTAssertTrue(hasNextPage)
        assertEqual(4, customers.count)
        assertEqual(0, customers[0].customerID)
        assertEqual(1, customers[1].customerID)
        assertEqual(2, customers[2].customerID)
        assertEqual(3, customers[3].customerID)
        assertEqual("Matt The Unregistered", customers[0].name)
        assertEqual("John", customers[1].name)
        assertEqual("", customers[2].name)
        assertEqual("John Doe", customers[3].name)
    }

    func test_synchronizeAllCustomers_returns_Error_upon_failure() {
        // Given
        let expectedError = NetworkError.notFound()
        network.simulateError(requestUrlSuffix: "", error: expectedError)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = CustomerAction.synchronizeAllCustomers(siteID: self.dummySiteID, pageNumber: 1, pageSize: 2) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_searchWCAnalyticsCustomers_upserts_the_returned_WCAnalyticsCustomerSearchResult() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers", filename: "wc-analytics-customers")

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.WCAnalyticsCustomerSearchResult.self), 0)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = CustomerAction.searchWCAnalyticsCustomers(siteID: self.dummySiteID,
                                                                   pageNumber: 1,
                                                                   pageSize: 25,
                                                                   keyword: self.dummyKeyword,
                                                                   filter: .name) { result in
                promise(result)
            }
            self.dispatcher.dispatch(action)
        }

        // Then
        let hasMoreCustomers = try XCTUnwrap(result.get())
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(hasMoreCustomers)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.WCAnalyticsCustomer.self), 4)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.WCAnalyticsCustomerSearchResult.self), 1)

        let storedCustomerSearchResults = viewStorage.loadWCAnalyticsCustomerSearchResult(siteID: dummySiteID, keyword: dummyKeyword)

        XCTAssertNotNil(storedCustomerSearchResults)
        XCTAssertEqual(storedCustomerSearchResults?.siteID, dummySiteID)
        XCTAssertEqual(storedCustomerSearchResults?.keyword, dummyKeyword)
        XCTAssertEqual(storedCustomerSearchResults?.customers?.count, 4)
    }

    func test_searchWCAnalyticsCustomers_returns_Error_upon_failure() {
        // Given
        let expectedError = NetworkError.notFound()
        network.simulateError(requestUrlSuffix: "", error: expectedError)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = CustomerAction.searchWCAnalyticsCustomers(siteID: self.dummySiteID,
                                                                   pageNumber: 1,
                                                                   pageSize: 25,
                                                                   keyword: self.dummyKeyword,
                                                                   filter: .name) { result in
                promise(result)
            }
            self.dispatcher.dispatch(action)
        }

        //Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }
}
