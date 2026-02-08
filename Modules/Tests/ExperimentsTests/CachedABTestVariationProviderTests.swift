import Testing
@testable import Experiments

@Suite("Cached AB Test Variation Provider Tests")
struct CachedABTestVariationProviderTests {
    @Test func test_variation_is_control_when_the_value_does_not_exist() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))

        // When
        let cache = VariationCache(userDefaults: userDefaults)
        let provider = CachedABTestVariationProvider(cache: cache)

        // Then
        #expect(provider.variation(for: .mockLoggedOut) == .control)
    }

    @Test func test_correct_variation_is_returned_after_caching_it() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)
        let provider = CachedABTestVariationProvider(cache: cache)

        // When
        try cache.assign(variation: .treatment, for: .mockLoggedOut)

        // Then
        #expect(provider.variation(for: .mockLoggedOut) == .treatment)
    }
}
