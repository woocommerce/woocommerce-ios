public struct WooCommerceFeature: Codable {
    var id = UUID()
    let title: String
    let subtitle: String
    let iconUrl: String

    public init(title: String, subtitle: String, iconUrl: String) {
        self.title = title
        self.subtitle = subtitle
        self.iconUrl = iconUrl
    }
}
