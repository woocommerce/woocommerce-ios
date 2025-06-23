/// Models a Feature that belongs to an Announcement
/// These entities will be serialised to a plist file

public struct Feature: Codable {
    public let title: String
    public let subtitle: String
    public let icons: [FeatureIcon]?
    public let iconUrl: String
    public let iconBase64: String?

    public init(title: String,
                subtitle: String,
                icons: [FeatureIcon]?,
                iconUrl: String,
                iconBase64: String?) {
        self.title = title
        self.subtitle = subtitle
        self.icons = icons
        self.iconUrl = iconUrl
        self.iconBase64 = iconBase64
    }
}
