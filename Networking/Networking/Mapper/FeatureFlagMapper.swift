import Foundation

/// Mapper: Feature FLag
///
struct FeatureFlagMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Feature Flags.
    ///
    func map(response: Data) throws -> FeatureFlagList {
        return try JSONDecoder().decode(MapperInternalFlagList.self, from: response).featureFlags
    }

    /// Because the feature flag names can't be known at compile-time we need to read them dynamically – this object decodes them into an array
    /// that can be passed out of the Mapper.
    struct MapperInternalFlagList: Decodable {

        let featureFlags: FeatureFlagList

        struct DynamicKey: CodingKey {
            var stringValue: String
            init(stringValue: String) {
                self.stringValue = stringValue
            }

            /// These are required for protocol conformance but don't actually do anything
            var intValue: Int?
            init(intValue: Int) {
                self.intValue = intValue
                self.stringValue = "\(intValue)"
            }
        }

        /// Create a new `DynamicFeatureFlagList` from JSON
        init(from decoder: Decoder) throws {
            let dynamicKeysContainer = try decoder.container(keyedBy: DynamicKey.self)

            self.featureFlags = try dynamicKeysContainer.allKeys.map {
                let key = $0.stringValue
                let value = try dynamicKeysContainer.decode(Bool.self, forKey: $0)
                return FeatureFlag(title: key, value: value)
            }
        }
    }
}
