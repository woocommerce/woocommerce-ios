public struct Feature: Codable {
    public let title: String
    public let subtitle: String
    public let iconUrl: String

    public init(title: String, subtitle: String, iconUrl: String) {
        self.title = title
        self.subtitle = subtitle
        self.iconUrl = iconUrl
    }
}
