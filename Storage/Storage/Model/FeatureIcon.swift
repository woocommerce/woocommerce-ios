/// Models a Feature Icon that belongs to an Feature
///
public struct FeatureIcon: Codable {
    public let iconUrl: String
    public let iconBase64: String
    public let iconType: String

    public init(iconUrl: String,
                iconBase64: String,
                iconType: String) {
        self.iconUrl = iconUrl
        self.iconBase64 = iconBase64
        self.iconType = iconType
    }
}
