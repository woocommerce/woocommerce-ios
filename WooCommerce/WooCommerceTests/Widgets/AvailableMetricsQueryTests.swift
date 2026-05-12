import Testing
@testable import WooCommerce

struct AvailableMetricsQueryTests {

    @Test func suggested_entities_when_authentication_mode_is_wpcom_then_returns_full_catalog() async throws {
        // Given
        let query = AvailableMetricsQuery(authenticationMode: { .wpcom })

        // When
        let entities = try await query.suggestedEntities()

        // Then
        #expect(entities == StoreInfoMetricType.allCases)
        #expect(entities.count == 7)
    }

    @Test func suggested_entities_when_authentication_mode_is_unknown_then_returns_site_credential_compatible_metrics() async throws {
        // Given
        let query = AvailableMetricsQuery(authenticationMode: { .unknown })

        // When
        let entities = try await query.suggestedEntities()

        // Then
        #expect(entities == StoreInfoMetricType.allCases.filter(\.isAvailableWithSiteCredentials))
        #expect(entities.count == 5)
    }

    @Test func suggested_entities_when_authentication_mode_is_site_credentials_then_returns_site_credential_compatible_metrics() async throws {
        // Given
        let query = AvailableMetricsQuery(authenticationMode: { .siteCredentials })

        // When
        let entities = try await query.suggestedEntities()

        // Then
        #expect(entities == StoreInfoMetricType.allCases.filter(\.isAvailableWithSiteCredentials))
        #expect(entities.count == 5)
    }

    @Test func entities_for_identifiers_when_authentication_mode_is_site_credentials_then_resolves_hidden_metrics() async throws {
        // Given
        let query = AvailableMetricsQuery(authenticationMode: { .siteCredentials })
        let identifiers = [
            StoreInfoMetricType.conversion.id,
            StoreInfoMetricType.visitors.id,
            StoreInfoMetricType.revenue.id
        ]

        // When
        let entities = try await query.entities(for: identifiers)

        // Then
        #expect(entities == [.conversion, .visitors, .revenue])
    }
}
