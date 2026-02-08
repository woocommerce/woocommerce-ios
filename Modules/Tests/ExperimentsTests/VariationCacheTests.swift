import Testing
@testable import Experiments

@Suite("Variation Cache Tests")
struct VariationCacheTests {
    @Test func test_variation_is_nil_when_the_value_does_not_exist() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))

        // When
        let cache = VariationCache(userDefaults: userDefaults)

        // Then
        #expect(cache.variation(for: .mockLoggedOut) == nil)
    }

    @Test func test_correct_variation_is_returned_after_setting_it() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)

        // When
        try cache.assign(variation: .treatment, for: .mockLoggedOut)

        // Then
        #expect(cache.variation(for: .mockLoggedOut) == .treatment)
    }

    @Test func test_it_throws_when_trying_to_cache_logged_in_experiment() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)

        // When
        #expect(throws: (any Error).self) { try cache.assign(variation: .treatment, for: .mockLoggedIn) }
    }
}
