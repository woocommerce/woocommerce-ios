import Foundation
import XCTest
@testable import WooCommerce
import Yosemite

final class CustomerSelectorViewModelTests: XCTestCase {
    var viewModel: CustomerSelectorViewModel!
    var stores: MockStoresManager!

    let sampleSiteID: Int64 = 123

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
    }

    func test_loadCustomersListData_calls_to_synchronizeLightCustomersData() {
        // Given
        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores) { _ in }

        var passedSiteID: Int64?
        var passedPageNumber: Int?
        var passedPageSize: Int?

        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            switch action {
            case let .synchronizeLightCustomersData(siteID, pageNumber, pageSize, onCompletion):
                passedSiteID = siteID
                passedPageNumber = pageNumber
                passedPageSize = pageSize
                onCompletion(.success(true))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        waitForExpectation { expectation in
            viewModel.loadCustomersListData() { _ in
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(passedSiteID, sampleSiteID)
        XCTAssertEqual(passedPageNumber, 1)
        XCTAssertEqual(passedPageSize, 25)
    }

    func test_loadCustomersListData_calls_to_synchronizeLightCustomersData_and_passes_error() {
        // Given
        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores) { _ in }
        let error = NSError(domain: "Test", code: -1001)

        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            switch action {
            case let .synchronizeLightCustomersData(_, _, _, onCompletion):
                onCompletion(.failure(error))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        var passedError: NSError?
        waitForExpectation { expectation in
            viewModel.loadCustomersListData() { result in
                if case let .failure(error) = result {
                    passedError = error as NSError

                }
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(passedError, error)
    }

    func test_onCustomerSelected_when_customerID_is_0_passes_customer_and_finishes_succesfully() {
        // Given
        var passedCustomer: Customer?
        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores) { customer in
            passedCustomer = customer
        }

        // When
        let notRegisteredCustomer = Customer.fake().copy(customerID: 0)

        var returnedResult: (Result<(), any Error>)?
        waitForExpectation { expectation in
            viewModel.onCustomerSelected(notRegisteredCustomer) { result in
                returnedResult = result
                expectation.fulfill()
            }
        }

        guard case .success(()) = returnedResult else {
            XCTFail()

            return
        }

        XCTAssertEqual(passedCustomer, notRegisteredCustomer)
    }

    func test_onCustomerSelected_when_customerID_is_not_0_retrieves_customer_full_data_and_finishes_succesfully() {
        // Given
        var passedCustomer: Customer?
        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores) { customer in
            passedCustomer = customer
        }

        let returnedCustomer = Customer.fake().copy(customerID: 23, lastName: "Testion")

        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            switch action {
            case let .retrieveCustomer(_, _, onCompletion):
                onCompletion(.success(returnedCustomer))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let registeredCustomer = Customer.fake().copy(customerID: 23)

        var returnedResult: (Result<(), any Error>)?
        waitForExpectation { expectation in
            viewModel.onCustomerSelected(registeredCustomer) { result in
                returnedResult = result
                expectation.fulfill()
            }
        }

        guard case .success(()) = returnedResult else {
            XCTFail()

            return
        }

        XCTAssertEqual(passedCustomer, returnedCustomer)
    }

    func test_onCustomerSelected_calls_to_retrieveCustomer_and_passes_error() {
        // Given
        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores) { _ in }
        let error = NSError(domain: "Test", code: -1001)

        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            switch action {
            case let .retrieveCustomer(_, _, onCompletion):
                onCompletion(.failure(error))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let registeredCustomer = Customer.fake().copy(customerID: 23)
        var passedError: NSError?
        waitForExpectation { expectation in
            viewModel.onCustomerSelected(registeredCustomer) { result in
                if case let .failure(error) = result {
                    passedError = error as NSError

                }
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(passedError, error)
    }
}
