import Testing
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct ServerRefundAvailabilityCacheTests {

    @Test func availability_is_tristate_and_isolated_per_site() {
        // Given
        let cache = ServerRefundAvailabilityCache()
        #expect(cache.isAvailable(siteID: 1) == nil)

        // When
        cache.markAvailable(siteID: 1)
        cache.markUnavailable(siteID: 2)

        // Then
        #expect(cache.isAvailable(siteID: 1) == true)
        #expect(cache.isAvailable(siteID: 2) == false)
        #expect(cache.isAvailable(siteID: 3) == nil)
    }

    @Test func nonpositive_site_ids_are_never_cached() {
        // Given application-password (non-Jetpack) sites all share the placeholder site ID, so a
        // verdict for one such store must never leak into another.
        let cache = ServerRefundAvailabilityCache()

        // When
        cache.markUnavailable(siteID: -1)
        cache.markAvailable(siteID: 0)

        // Then
        #expect(cache.isAvailable(siteID: -1) == nil)
        #expect(cache.isAvailable(siteID: 0) == nil)
    }
}
