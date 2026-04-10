import AutomatticTracks

/// Cache based implementation of `ABTestVariationProvider`
///
public struct CachedABTestVariationProvider: ABTestVariationProvider {

    private let cache: VariationCache

    public init(cache: VariationCache = VariationCache(userDefaults: .standard)) {
        self.cache = cache
    }

    public func variation(for abTest: ABTest) -> Variation {
        // We cache only logged out ABTests as they are assigned based on `anonId` by `ExPlat`.
        // There will be one value assigned to one device and it won't change.
        //
        guard abTest.context == .loggedOut else {
            return abTest.variation ?? .control
        }

        if let variation = abTest.variation {
            try? cache.assign(variation: variation, for: abTest)
            return variation
        } else if let cachedVariation = cache.variation(for: abTest) {
            return cachedVariation
        } else {
            return .control
        }
    }
}
