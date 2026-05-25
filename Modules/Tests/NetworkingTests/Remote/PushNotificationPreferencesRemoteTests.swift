import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

struct PushNotificationPreferencesRemoteTests {
    private let network = MockNetwork()
    private let sampleSiteID: Int64 = 1234

    // MARK: - Request shape

    @Test func loadPreferences_then_sends_GET_to_wc_push_notifications_preferences() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)

        // When
        _ = try? await remote.loadPreferences(siteID: sampleSiteID)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.path == "wc-push-notifications/preferences")
        #expect(request.method == .get)
        #expect(request.siteID == sampleSiteID)
    }

    @Test func updatePreferences_then_sends_POST_to_wc_push_notifications_preferences() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        let changes = PushNotificationPreferences(storeOrder: .init(enabled: false))

        // When
        _ = try? await remote.updatePreferences(siteID: sampleSiteID, changes: changes)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.path == "wc-push-notifications/preferences")
        #expect(request.method == .post)
        #expect(request.siteID == sampleSiteID)
    }

    @Test func updatePreferences_when_only_one_subfield_set_then_serializes_only_that_subfield() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        let changes = PushNotificationPreferences(storeStock: .init(onBackorder: false))

        // When
        _ = try? await remote.updatePreferences(siteID: sampleSiteID, changes: changes)

        // Then — the wire body should be exactly { "store_stock": { "on_backorder": false } }.
        let parameters = try #require(network.queryParametersDictionary)
        #expect(parameters.count == 1)
        let storeStock = try #require(parameters["store_stock"] as? [String: Any])
        #expect(storeStock.count == 1)
        #expect(storeStock["on_backorder"] as? Bool == false)
        #expect(parameters["store_order"] == nil)
        #expect(parameters["store_review"] == nil)
    }

    @Test func updatePreferences_when_multiple_subfields_set_then_serializes_only_those() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        let changes = PushNotificationPreferences(
            storeOrder: .init(enabled: true, minAmount: 100),
            storeReview: .init(maxRating: 3)
        )

        // When
        _ = try? await remote.updatePreferences(siteID: sampleSiteID, changes: changes)

        // Then
        let parameters = try #require(network.queryParametersDictionary)
        #expect(parameters["store_stock"] == nil)

        let storeOrder = try #require(parameters["store_order"] as? [String: Any])
        #expect(storeOrder.count == 2)
        #expect(storeOrder["enabled"] as? Bool == true)
        #expect(storeOrder["min_amount"] as? Int == 100)

        let storeReview = try #require(parameters["store_review"] as? [String: Any])
        #expect(storeReview.count == 1)
        #expect(storeReview["max_rating"] as? Int == 3)
        #expect(storeReview["enabled"] == nil)
    }

    @Test func updatePreferences_when_storeOrder_minAmount_is_nil_then_sends_explicit_null() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        let changes = PushNotificationPreferences(storeOrder: .init(enabled: false, minAmount: nil))

        // When
        _ = try? await remote.updatePreferences(siteID: sampleSiteID, changes: changes)

        // Then — the wire body must include `min_amount` as JSON null so the server clears the threshold.
        let parameters = try #require(network.queryParametersDictionary)
        let storeOrder = try #require(parameters["store_order"] as? [String: Any])
        #expect(storeOrder.count == 2)
        #expect(storeOrder["enabled"] as? Bool == false)
        #expect(storeOrder["min_amount"] is NSNull)
    }

    @Test func updatePreferences_when_storeReview_maxRating_is_nil_then_sends_explicit_null() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        let changes = PushNotificationPreferences(storeReview: .init(enabled: true, maxRating: nil))

        // When
        _ = try? await remote.updatePreferences(siteID: sampleSiteID, changes: changes)

        // Then — the wire body must include `max_rating` as JSON null so the server clears
        // the rating cap (the "All new reviews" selection on the detail screen).
        let parameters = try #require(network.queryParametersDictionary)
        let storeReview = try #require(parameters["store_review"] as? [String: Any])
        #expect(storeReview.count == 2)
        #expect(storeReview["enabled"] as? Bool == true)
        #expect(storeReview["max_rating"] is NSNull)
    }

    // MARK: - Response decoding

    @Test func loadPreferences_then_decodes_full_response() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/preferences",
                                 filename: "push-notification-preferences")

        // When
        let preferences = try await remote.loadPreferences(siteID: sampleSiteID)

        // Then
        #expect(preferences.storeOrder?.enabled == true)
        #expect(preferences.storeOrder?.minAmount == nil)

        #expect(preferences.storeReview?.enabled == true)
        #expect(preferences.storeReview?.maxRating == 5)

        #expect(preferences.storeStock?.enabled == true)
        #expect(preferences.storeStock?.lowStock == true)
        #expect(preferences.storeStock?.outOfStock == true)
        #expect(preferences.storeStock?.onBackorder == false)
    }

    @Test func loadPreferences_when_unknown_top_level_key_present_then_known_fields_still_decode() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/preferences",
                                 filename: "push-notification-preferences-forward-compat")

        // When
        let preferences = try await remote.loadPreferences(siteID: sampleSiteID)

        // Then — unknown `future_type` is ignored; known types decode normally.
        #expect(preferences.storeOrder?.enabled == true)
        #expect(preferences.storeOrder?.minAmount == Decimal(string: "25.5"))
    }

    @Test func loadPreferences_when_subfield_missing_then_decodes_as_nil() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/preferences",
                                 filename: "push-notification-preferences-forward-compat")

        // When
        let preferences = try await remote.loadPreferences(siteID: sampleSiteID)

        // Then — store_review has only `enabled` populated in the fixture.
        #expect(preferences.storeReview?.enabled == true)
        #expect(preferences.storeReview?.maxRating == nil)
        // store_stock is entirely absent from the fixture.
        #expect(preferences.storeStock == nil)
    }

    @Test func loadPreferences_when_network_error_then_throws() async {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)

        // When / Then — no simulated response triggers `NetworkError.notFound`.
        await #expect(throws: (any Error).self) {
            _ = try await remote.loadPreferences(siteID: self.sampleSiteID)
        }
    }

    @Test func updatePreferences_then_returns_decoded_merged_response() async throws {
        // Given
        let remote = PushNotificationPreferencesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/preferences",
                                 filename: "push-notification-preferences")
        let changes = PushNotificationPreferences(storeStock: .init(onBackorder: false))

        // When
        let preferences = try await remote.updatePreferences(siteID: sampleSiteID, changes: changes)

        // Then — server returns the full merged shape regardless of how thin the request was.
        #expect(preferences.storeOrder?.enabled == true)
        #expect(preferences.storeReview?.maxRating == 5)
        #expect(preferences.storeStock?.onBackorder == false)
    }
}
