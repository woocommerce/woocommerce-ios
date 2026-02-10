import Foundation
import Testing
@testable import Experiments

struct `Cached AB Test Variation Provider Tests` {
    @Test func `variation is control when the value does not exist`() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))

        // When
        let cache = VariationCache(userDefaults: userDefaults)
        let provider = CachedABTestVariationProvider(cache: cache)

        // Then
        #expect(provider.variation(for: .mockLoggedOut) == .control)
    }

    @Test func `correct variation is returned after caching it`() throws {
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
