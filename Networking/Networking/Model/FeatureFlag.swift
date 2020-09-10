import Foundation

public struct FeatureFlag {
    public let title: String
    public let value: Bool

    public init(title: String, value: Bool) {
        self.title = title
        self.value = value
    }
}

public typealias FeatureFlagList = [FeatureFlag]
