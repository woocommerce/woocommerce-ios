import XCTest

@testable import WooCommerce
import Yosemite

final class ProductSearchUICommandTests: XCTestCase {
    private let sampleSiteID: Int64 = 134
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    // MARK: - `createHeaderView`

    func test_createHeaderView_returns_a_non_nil_view() {
        // When
        let command = ProductSearchUICommand(siteID: sampleSiteID, isSearchProductsBySKUEnabled: true)

        // Then
        XCTAssertNotNil(command.createHeaderView())
    }

    func test_createHeaderView_returns_nil_when_searchProductsBySKU_is_disabled() {
        // When
        let command = ProductSearchUICommand(siteID: sampleSiteID, isSearchProductsBySKUEnabled: false)

        // Then
        XCTAssertNil(command.createHeaderView())
    }

    // MARK: - `searchResultsPredicate`

    func test_searchResultsPredicate_is_nil_when_keyword_is_empty() {
        // Given
        let command = ProductSearchUICommand(siteID: sampleSiteID, isSearchProductsBySKUEnabled: true)

        // When
        let predicate = command.searchResultsPredicate(keyword: "")

        // Then
        XCTAssertNil(predicate)
    }

    func test_searchResultsPredicate_includes_keyword_and_filter_when_keyword_is_not_empty() {
        // Given
        let command = ProductSearchUICommand(siteID: sampleSiteID, isSearchProductsBySKUEnabled: true)

        // When
        let predicate = command.searchResultsPredicate(keyword: "🍁")

        // Then
        XCTAssertEqual(predicate?.predicateFormat,
                       "SUBQUERY(searchResults, $result, $result.keyword == \"🍁\" AND $result.filterKey == \"all\").@count > 0")
    }

    func test_searchResultsPredicate_matches_any_products_with_search_results_when_keyword_is_empty_and_searchProductsBySKU_is_disabled() {
        // Given
        let command = ProductSearchUICommand(siteID: sampleSiteID, isSearchProductsBySKUEnabled: false)

        // When
        let predicate = command.searchResultsPredicate(keyword: "")

        // Then
        XCTAssertEqual(predicate?.predicateFormat, "ANY searchResults.keyword == \"\"")
    }

    func test_searchResultsPredicate_includes_keyword_and_filter_when_keyword_is_not_empty_and_searchProductsBySKU_is_disabled() {
        // Given
        let command = ProductSearchUICommand(siteID: sampleSiteID, isSearchProductsBySKUEnabled: false)

        // When
        let predicate = command.searchResultsPredicate(keyword: "Pineapple")

        // Then
        XCTAssertEqual(predicate?.predicateFormat, "ANY searchResults.keyword == \"Pineapple\"")
    }

    // MARK: - `synchronizeModels`

    func test_synchronizeModels_does_not_dispatch_search_action_when_the_last_keyword_is_the_same_for_the_first_page() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let command = ProductSearchUICommand(siteID: sampleSiteID, stores: stores, isSearchProductsBySKUEnabled: true)

        var invocationCount = 0
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            invocationCount += 1
            onCompletion(.success(()))
        }

        // When
        // Syncing models for the first time for the first page.
        waitFor { promise in
            command.synchronizeModels(siteID: self.sampleSiteID, keyword: "Melon", pageNumber: 1, pageSize: 10) { success in
                promise(())
            }
        }
        XCTAssertEqual(invocationCount, 1)

        // Syncing models for the same keyword for the second time for the first page.
        waitFor { promise in
            command.synchronizeModels(siteID: self.sampleSiteID, keyword: "Melon", pageNumber: 1, pageSize: 10) { success in
                promise(())
            }
        }
        XCTAssertEqual(invocationCount, 1)

        // Syncing models for the same keyword for the third time, but for the second page.
        waitFor { promise in
            command.synchronizeModels(siteID: self.sampleSiteID, keyword: "Melon", pageNumber: 2, pageSize: 10) { success in
                promise(())
            }
        }
        XCTAssertEqual(invocationCount, 2)
    }

    func test_synchronizeModels_does_not_dispatch_search_action_when_keyword_is_empty() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let command = ProductSearchUICommand(siteID: sampleSiteID, isSearchProductsBySKUEnabled: true)

        var invocationCount = 0
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            invocationCount += 1
            onCompletion(.success(()))
        }

        // When
        waitFor { promise in
            command.synchronizeModels(siteID: self.sampleSiteID, keyword: "", pageNumber: 1, pageSize: 10) { _ in
                promise(())
            }
        }

        // Then
        XCTAssertEqual(invocationCount, 0)
    }

    // MARK: - Analytics

    func test_productListSearched_is_tracked_when_synchronizing_models() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let command = ProductSearchUICommand(siteID: sampleSiteID, stores: stores, analytics: analytics, isSearchProductsBySKUEnabled: true)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            onCompletion(.success(()))
        }

        // When
        waitFor { promise in
            command.synchronizeModels(siteID: self.sampleSiteID, keyword: "coffee", pageNumber: 1, pageSize: 10) { _ in
                promise(())
            }
        }

        // Then
        let event = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(event, "product_list_searched")
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(eventProperties["filter"] as? String, "all")
    }
}
