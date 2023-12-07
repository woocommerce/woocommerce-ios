import XCTest
@testable import Networking

final class SubscriptionListMapperTests: XCTestCase {

    private let sampleSiteID: Int64 = 12983476

    func test_SubscriptionList_map_parses_all_subscriptions_in_response() async throws {
        // Given
        let subscriptions = try await mapLoadSubscriptionListResponseWithDataEnvelope()

        // Then
        XCTAssertEqual(subscriptions.count, 2)
    }

    func test_SubscriptionList_map_parses_all_coupons_in_response_without_data_envelope() async throws {
        // Given
        let subscriptions = try await mapLoadSubscriptionListResponseWithoutDataEnvelope()

        // Then
        XCTAssertEqual(subscriptions.count, 2)
    }

    func test_SubscriptionList_map_includes_siteID_in_parsed_results() async throws {
        // Given
        let subscriptions = try await mapLoadSubscriptionListResponseWithDataEnvelope()

        // Then
        XCTAssertTrue(subscriptions.count > 0)
        for subscription in subscriptions {
            XCTAssertEqual(subscription.siteID, sampleSiteID)
        }
    }

    func test_SubscriptionList_map_parses_all_fields_in_result() async throws {
        // Given
        let subscriptions = try await mapLoadSubscriptionListResponseWithDataEnvelope()
        let subscription = subscriptions[0]

        // Then
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let startDate = try XCTUnwrap(dateFormatter.date(from: "2023-01-31T16:29:46"))
        let endDate = try XCTUnwrap(dateFormatter.date(from: "2023-04-25T16:29:46"))
        let expectedSubscription = Subscription(siteID: sampleSiteID,
                                                subscriptionID: 282,
                                                parentID: 281,
                                                status: .active,
                                                currency: "USD",
                                                billingPeriod: .week,
                                                billingInterval: "1",
                                                total: "14.50",
                                                startDate: startDate,
                                                endDate: endDate)

        assertEqual(expectedSubscription, subscription)
    }

}

// MARK: - Test Helpers
///
private extension SubscriptionListMapperTests {

    /// Returns the SubscriptionListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSubscriptions(from filename: String) async throws -> [Subscription] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try await SubscriptionListMapper(siteID: sampleSiteID).map(response: response)
    }

    /// Returns the SubscriptionListMapper output from `subscription-list.json`
    ///
    func mapLoadSubscriptionListResponseWithDataEnvelope() async throws -> [Subscription] {
        return try await mapSubscriptions(from: "subscription-list")
    }

    /// Returns the SubscriptionListMapper output from `subscription-list-without-data.json`
    ///
    func mapLoadSubscriptionListResponseWithoutDataEnvelope() async throws -> [Subscription] {
        return try await mapSubscriptions(from: "subscription-list-without-data")
    }
}
