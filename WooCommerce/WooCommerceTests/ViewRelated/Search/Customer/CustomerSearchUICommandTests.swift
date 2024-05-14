import XCTest
@testable import WooCommerce
import Yosemite
import protocol WooFoundation.Analytics

final class CustomerSearchUICommandTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    func test_searchResultsPredicate_includes_siteID_and_keyword_when_keyword() {
        // Given
        let command = CustomerSearchUICommand(siteID: sampleSiteID) { _ in }

        // When
        let predicate = command.searchResultsPredicate(keyword: "some")
        let expectedQuery = "siteID == 123 AND ANY searchResults.keyword == \"some\""

        // Then
        XCTAssertEqual(predicate?.predicateFormat, expectedQuery)
    }

    func test_searchResultsPredicate_when_better_customer_selection_is_enabled_and_keyword_is_empty_then_returns_nil() {
        // Given
        let command = CustomerSearchUICommand(siteID: sampleSiteID, featureFlagService: MockFeatureFlagService(betterCustomerSelectionInOrder: true)) { _ in }

        // When
        let predicate = command.searchResultsPredicate(keyword: "")

        // Then
        XCTAssertNil(predicate)
    }

    func test_cellViewModel_display_correct_customer_details() {
        let command = CustomerSearchUICommand(siteID: sampleSiteID) { _ in }
        let customer = Customer(
            siteID: sampleSiteID,
            customerID: 1,
            email: "john.w@email.com",
            username: "john",
            firstName: "John",
            lastName: "W",
            billing: nil,
            shipping: nil
        )

        let cellViewModel = command.createCellViewModel(model: customer)

        XCTAssertEqual(cellViewModel.id, String(customer.customerID))
        XCTAssertEqual(cellViewModel.title, "\(customer.firstName ?? "") \(customer.lastName ?? "")")
        XCTAssertEqual(cellViewModel.subtitle, String(customer.email))
    }

    func test_CustomerSearchUICommand_when_synchronizeModels_then_tracks_orderCreationCustomerSearch_event() {
        // Given
        let command = CustomerSearchUICommand(
            siteID: sampleSiteID,
            analytics: analytics) { _ in }

        // When
        command.synchronizeModels(
            siteID: sampleSiteID,
            keyword: "",
            pageNumber: 1,
            pageSize: 1,
            onCompletion: { _ in }
        )

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains("order_creation_customer_search"))
    }

    func test_didSelectSearchResult_then_tracks_orderCreationCustomerAdded_event() {
        // Given
        let command = CustomerSearchUICommand(
            siteID: sampleSiteID,
            analytics: analytics) { _ in }

        // When
        command.didSelectSearchResult(model: Customer.fake(), from: UIViewController(), reloadData: {}, updateActionButton: {})

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains("order_creation_customer_added"))
    }

    func test_synchronizeModels_when_and_keyword_is_empty_and_loadResultsWhenSearchTermIsEmpty_is_true_then_calls_synchronizeAllLightCustomersDataAction() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        // Given
        let command = CustomerSearchUICommand(siteID: sampleSiteID,
                                              loadResultsWhenSearchTermIsEmpty: true,
                                              stores: stores,
                                              featureFlagService: MockFeatureFlagService(betterCustomerSelectionInOrder: true)) { _ in }

        var invocationCount = 0
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeLightCustomersData(_, _, _, _, _, _, onCompletion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            invocationCount += 1
            onCompletion(.success(true))
        }

        // When
        waitFor { promise in
            command.synchronizeModels(siteID: self.sampleSiteID, keyword: "", pageNumber: 1, pageSize: 10) { _ in
                promise(())
            }
        }

        // Then
        XCTAssertEqual(invocationCount, 1)
    }

    func test_synchronizeModels_when_and_keyword_is_empty_and_loadResultsWhenSearchTermIsEmpty_is_false_then_calls_deleteAllCustomers() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        // Given
        let command = CustomerSearchUICommand(siteID: sampleSiteID,
                                              loadResultsWhenSearchTermIsEmpty: false,
                                              stores: stores,
                                              featureFlagService: MockFeatureFlagService(betterCustomerSelectionInOrder: true)) { _ in }

        var invocationCount = 0
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .deleteAllCustomers(_, onCompletion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            invocationCount += 1
            onCompletion()
        }

        // When
        waitFor { promise in
            command.synchronizeModels(siteID: self.sampleSiteID, keyword: "", pageNumber: 1, pageSize: 10) { _ in
                promise(())
            }
        }

        // Then
        XCTAssertEqual(invocationCount, 1)
    }
}
