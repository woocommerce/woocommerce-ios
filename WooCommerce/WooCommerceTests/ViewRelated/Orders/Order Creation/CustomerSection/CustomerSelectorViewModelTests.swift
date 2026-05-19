import Foundation
import XCTest
@testable import WooCommerce
import Yosemite
import Networking

@MainActor
final class CustomerSelectorViewModelTests: XCTestCase {
    var viewModel: CustomerSelectorViewModel!
    var stores: MockStoresManager!

    let sampleSiteID: Int64 = 123

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
    }

    func test_isEligibleForAdvancedSearch_when_wc_plugin_version_is_lower_than_minimum_then_return_false() {
        // Given
        let returnedVersion = "7.9.9"
        let mockPluginsService = MockPluginsService()
        let wooPlugin = SystemPlugin.fake().copy(version: returnedVersion, active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooPlugin)

        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores, pluginsService: mockPluginsService) { _ in }

        // When
        let isEligible = viewModel.isEligibleForAdvancedSearch()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForAdvancedSearch_when_wc_plugin_version_is_the_minimum_then_returns_true() {
        // Given
        let returnedVersion = "8.0.0-beta.1"
        let mockPluginsService = MockPluginsService()
        let wooPlugin = SystemPlugin.fake().copy(version: returnedVersion, active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooPlugin)

        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores, pluginsService: mockPluginsService) { _ in }

        // When
        let isEligible = viewModel.isEligibleForAdvancedSearch()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForAdvancedSearch_when_wc_plugin_version_is_higher_than_minimum_then_returns_true() {
        // Given
        let returnedVersion = "14.2.5"
        let mockPluginsService = MockPluginsService()
        let wooPlugin = SystemPlugin.fake().copy(version: returnedVersion, active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooPlugin)

        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores, pluginsService: mockPluginsService) { _ in }

        // When
        let isEligible = viewModel.isEligibleForAdvancedSearch()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForAdvancedSearch_when_wc_plugin_version_is_higher_than_minimum_but_plugin_is_not_active_then_returns_false() {
        // Given
        let returnedVersion = "14.2.5"
        let mockPluginsService = MockPluginsService()
        let wooPlugin = SystemPlugin.fake().copy(version: returnedVersion, active: false)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooPlugin)

        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores, pluginsService: mockPluginsService) { _ in }

        // When
        let isEligible = viewModel.isEligibleForAdvancedSearch()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_loadCustomersListData_calls_to_synchronizeLightCustomersData() {
        // Given
        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores) { _ in }

        var passedSiteID: Int64?
        var passedPageNumber: Int?
        var passedPageSize: Int?
        var passedOrderBy: WCAnalyticsCustomerRemote.OrderBy?
        var passedOrder: WCAnalyticsCustomerRemote.Order?
        var passedFilterEmpty: WCAnalyticsCustomerRemote.FilterEmpty?

        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            switch action {
            case let .synchronizeLightCustomersData(siteID, pageNumber, pageSize, orderby, order, filterEmpty, onCompletion):
                passedSiteID = siteID
                passedPageNumber = pageNumber
                passedPageSize = pageSize
                passedOrderBy = orderby
                passedOrder = order
                passedFilterEmpty = filterEmpty
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
        XCTAssertEqual(passedOrderBy, .name)
        XCTAssertEqual(passedOrder, .asc)
        XCTAssertEqual(passedFilterEmpty, .email)
    }

    func test_loadCustomersListData_calls_to_synchronizeLightCustomersData_and_passes_error() {
        // Given
        let viewModel = CustomerSelectorViewModel(siteID: sampleSiteID, stores: stores) { _ in }
        let error = NSError(domain: "Test", code: -1001)

        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            switch action {
            case let .synchronizeLightCustomersData(_, _, _, _, _, _, onCompletion):
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
