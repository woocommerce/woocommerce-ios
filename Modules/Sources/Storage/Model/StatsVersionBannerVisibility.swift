/// A wrapper of a dictionary from stats version banner type to whether the banner should be shown.
/// These entities will be serialised to a plist file
///
public struct StatsVersionBannerVisibility: Codable, Equatable {
    /// The type of banner regarding stats version
    ///
    /// - v3ToV4: banner shown when stats v4 is available while v3 is last shown
    /// - v4ToV3: banner shown when stats v4 is unavailable anymore and is reverted back to v3
    public enum StatsVersionBanner: String, Codable {
        case v3ToV4
        case v4ToV3
    }

    public let visibilityByBanner: [StatsVersionBanner: Bool]

    public init(visibilityByBanner: [StatsVersionBanner: Bool]) {
        self.visibilityByBanner = visibilityByBanner
    }
}
