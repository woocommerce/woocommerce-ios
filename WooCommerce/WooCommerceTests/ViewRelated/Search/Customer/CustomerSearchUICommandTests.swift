import XCTest
@testable import WooCommerce
import Yosemite

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

    func test_cellViewModel_display_correct_customer_details() {
        let command = CustomerSearchUICommand(siteID: sampleSiteID) { _ in }
        let customer = Customer(
            siteID: sampleSiteID,
            customerID: 1,
            email: "john.w@email.com",
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
}
