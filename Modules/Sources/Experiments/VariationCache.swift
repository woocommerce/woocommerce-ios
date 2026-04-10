import AutomatticTracks

enum VariationCacheError: Error {
    case onlyLoggedOutExperimentsShouldBeCached
}

public struct VariationCache {
    private let variationKey = "VariationCacheKey"

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func variation(for abTest: ABTest) -> Variation? {
        guard abTest.context == .loggedOut else {
            return nil
        }

        guard let data = userDefaults.object(forKey: variationKey) as? Data,
              let cachedVariations = try? JSONDecoder().decode([CachedVariation].self, from: data),
              case let variation = cachedVariations.first(where: { $0.abTest == abTest })?.variation
        else {
            return nil
        }

        return variation
    }

    func assign(variation: Variation, for abTest: ABTest) throws {
        guard abTest.context == .loggedOut else {
            throw VariationCacheError.onlyLoggedOutExperimentsShouldBeCached
        }

        var variations = userDefaults.object(forKey: variationKey) as? [CachedVariation] ?? []
        variations.append(CachedVariation(abTest: abTest, variation: variation))

        let encodedVariation = try JSONEncoder().encode(variations)
        userDefaults.set(encodedVariation, forKey: variationKey)
    }
}

public struct CachedVariation: Codable {
    let abTest: ABTest
    let variation: Variation
}
