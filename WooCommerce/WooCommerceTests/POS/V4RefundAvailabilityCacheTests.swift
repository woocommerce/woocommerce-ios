import Testing
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct V4RefundAvailabilityCacheTests {

    @Test func availability_is_tristate_and_isolated_per_site() {
        // Given
        let cache = V4RefundAvailabilityCache()
        #expect(cache.isV4Available(siteID: 1) == nil)

        // When
        cache.markV4Available(siteID: 1)
        cache.markV4Unavailable(siteID: 2)

        // Then
        #expect(cache.isV4Available(siteID: 1) == true)
        #expect(cache.isV4Available(siteID: 2) == false)
        #expect(cache.isV4Available(siteID: 3) == nil)
    }

    @Test func nonpositive_site_ids_are_never_cached() {
        // Given application-password (non-Jetpack) sites all share the placeholder site ID, so a
        // verdict for one such store must never leak into another.
        let cache = V4RefundAvailabilityCache()

        // When
        cache.markV4Unavailable(siteID: -1)
        cache.markV4Available(siteID: 0)

        // Then
        #expect(cache.isV4Available(siteID: -1) == nil)
        #expect(cache.isV4Available(siteID: 0) == nil)
    }
}
