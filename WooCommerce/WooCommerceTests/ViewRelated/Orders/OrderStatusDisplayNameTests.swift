import Testing
import Yosemite
@testable import WooCommerce

/// Unit tests for `Collection where Element == OrderStatus`'s `displayName(for:)` helper.
///
/// Order status labels must prefer the server-provided `name` (which follows the store's
/// wp-admin language) over the app's own localized strings.
struct OrderStatusDisplayNameTests {

    @Test func test_displayName_when_matching_status_has_server_name_then_returns_server_name() {
        // Given
        let siteStatuses = [OrderStatus(name: "En cours", siteID: 1, slug: "processing", total: 0)]

        // When
        let result = siteStatuses.displayName(for: .processing)

        // Then — server name preferred over the app-localized "Processing"
        #expect(result == "En cours")
    }

    @Test func test_displayName_when_no_matching_status_then_falls_back_to_localizedName() {
        // Given — a status list that does not contain `.completed`
        let siteStatuses = [OrderStatus(name: "En cours", siteID: 1, slug: "processing", total: 0)]

        // When
        let result = siteStatuses.displayName(for: .completed)

        // Then
        #expect(result == OrderStatusEnum.completed.localizedName)
    }

    @Test func test_displayName_when_matching_status_has_nil_name_then_falls_back_to_localizedName() {
        // Given — a matching status whose server name is nil
        let siteStatuses = [OrderStatus(name: nil, siteID: 1, slug: "processing", total: 0)]

        // When
        let result = siteStatuses.displayName(for: .processing)

        // Then
        #expect(result == OrderStatusEnum.processing.localizedName)
    }

    @Test func test_displayName_when_matching_custom_status_then_returns_server_name() {
        // Given — a custom status whose server name differs from its slug
        let siteStatuses = [OrderStatus(name: "Awaiting Shipment", siteID: 1, slug: "awaiting-shipment", total: 0)]

        // When
        let result = siteStatuses.displayName(for: .custom("awaiting-shipment"))

        // Then
        #expect(result == "Awaiting Shipment")
    }

    @Test func test_displayName_when_unmatched_custom_status_then_falls_back_to_slug() {
        // Given — no matching status; for `.custom`, localizedName is the raw slug,
        // so the fallback preserves today's `name ?? slug` behavior for custom statuses.
        let siteStatuses: [OrderStatus] = []

        // When
        let result = siteStatuses.displayName(for: .custom("awaiting-shipment"))

        // Then
        #expect(result == "awaiting-shipment")
    }
}
