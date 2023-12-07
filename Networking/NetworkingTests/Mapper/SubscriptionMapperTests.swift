import XCTest
@testable import Networking

final class SubscriptionMapperTests: XCTestCase {

    private let sampleSiteID: Int64 = 12983476

    func test_Subscription_map_parses_subscription_in_response() async throws {
        // Given
        let subscription = try await mapLoadSubscriptionResponseWithDataEnvelope()

        // Then
        XCTAssertNotNil(subscription)
    }

    func test_Subscription_map_parses_subscription_in_response_without_data_envelope() async throws {
        // Given
        let subscription = try await mapLoadSubscriptionResponseWithoutDataEnvelope()

        // Then
        XCTAssertNotNil(subscription)
    }

    func test_Subscription_map_includes_siteID_in_parsed_result() async throws {
        // Given
        let subscription = try await mapLoadSubscriptionResponseWithDataEnvelope()

        // Then
        XCTAssertEqual(subscription.siteID, sampleSiteID)
    }

    func test_Subscription_map_parses_all_fields_in_result() async throws {
        // Given
        let subscription = try await mapLoadSubscriptionResponseWithDataEnvelope()

        // Then
        let expectedSubscription = Subscription(siteID: sampleSiteID,
                                                subscriptionID: 282,
                                                parentID: 281,
                                                status: .active,
                                                currency: "USD",
                                                billingPeriod: .week,
                                                billingInterval: "1",
                                                total: "14.50",
                                                startDate: DateFormatter.dateFromString(with: "2023-01-31T16:29:46"),
                                                endDate: DateFormatter.dateFromString(with: "2023-04-25T16:29:46"))

        assertEqual(expectedSubscription, subscription)
    }

}

// MARK: - Test Helpers
///
private extension SubscriptionMapperTests {

    /// Returns the SubscriptionMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSubscription(from filename: String) async throws -> Subscription {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await SubscriptionMapper(siteID: sampleSiteID).map(response: response)
    }

    /// Returns the SubscriptionMapper output from `subscription.json`
    ///
    func mapLoadSubscriptionResponseWithDataEnvelope() async throws -> Subscription {
        try await mapSubscription(from: "subscription")
    }

    /// Returns the SubscriptionMapper output from `subscription-without-data.json`
    ///
    func mapLoadSubscriptionResponseWithoutDataEnvelope() async throws -> Subscription {
        try await mapSubscription(from: "subscription-without-data")
    }

    struct FileNotFoundError: Error {}
}
